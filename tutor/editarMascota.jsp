<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();
    String idParam = request.getParameter("id");

    if (idParam == null) {
        response.sendRedirect(request.getContextPath() + "/tutor/listarMascotas.jsp");
        return;
    }

    int idMascota = Integer.parseInt(idParam);

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    String nombre = "", especie = "", raza = "", edad = "", sexo = "Macho";
    double peso = 0;
    String error = null;
    String exito = null;

    if ("POST".equals(request.getMethod())) {
        nombre  = request.getParameter("nombre");
        especie = request.getParameter("especie");
        raza    = request.getParameter("raza");
        edad    = request.getParameter("edad");
        sexo    = request.getParameter("sexo");
        String pesoStr = request.getParameter("peso");

        nombre  = nombre  != null ? nombre.trim()  : "";
        especie = especie != null ? especie.trim() : "";
        raza    = raza    != null ? raza.trim()    : "";
        edad    = edad    != null ? edad.trim()    : "";
        pesoStr = pesoStr != null ? pesoStr.trim() : "";

        if (nombre.isEmpty() || especie.isEmpty() || raza.isEmpty() || edad.isEmpty() || pesoStr.isEmpty()) {
            error = "Todos los campos son obligatorios.";
        } else {
            try {
                peso = Double.parseDouble(pesoStr);
                if (peso <= 0) throw new Exception("El peso debe ser mayor a 0.");
                PreparedStatement psUp = con.prepareStatement(
                    "UPDATE mascota m JOIN tutor t ON m.id_tutor = t.id_tutor " +
                    "SET m.nombre=?, m.especie=?, m.raza=?, m.edad=?, m.sexo=?, m.peso=? " +
                    "WHERE m.id_mascota=? AND t.correo=?");
                psUp.setString(1, nombre);
                psUp.setString(2, especie);
                psUp.setString(3, raza);
                psUp.setString(4, edad);
                psUp.setString(5, sexo);
                psUp.setDouble(6, peso);
                psUp.setInt(7, idMascota);
                psUp.setString(8, correo);
                psUp.executeUpdate();
                psUp.close();
                exito = "Mascota actualizada correctamente.";
            } catch (NumberFormatException nfe) {
                error = "El peso debe ser un número válido.";
            } catch (Exception e) {
                error = "Error al actualizar. Intenta de nuevo.";
            }
        }
    }

    // Cargar datos actuales de la mascota
    PreparedStatement psGet = con.prepareStatement(
        "SELECT m.nombre, m.especie, m.raza, m.edad, m.sexo, m.peso " +
        "FROM mascota m JOIN tutor t ON m.id_tutor = t.id_tutor " +
        "WHERE m.id_mascota = ? AND t.correo = ?");
    psGet.setInt(1, idMascota);
    psGet.setString(2, correo);
    ResultSet rs = psGet.executeQuery();

    if (rs.next()) {
        if (error == null && exito == null) {
            nombre  = rs.getString("nombre");
            especie = rs.getString("especie");
            raza    = rs.getString("raza");
            edad    = rs.getString("edad");
            sexo    = rs.getString("sexo");
            peso    = rs.getDouble("peso");
        }
    } else {
        rs.close(); psGet.close(); con.close();
        response.sendRedirect(request.getContextPath() + "/tutor/listarMascotas.jsp");
        return;
    }
    rs.close(); psGet.close(); con.close();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Editar Mascota – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">

    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/tutor/listarMascotas.jsp" class="btn-back">← Volver a mis mascotas</a>

        <div class="card card--register">
            <h2 class="card-title">Editar Mascota</h2>

            <% if (error != null) { %>
                <p class="error-msg" style="text-align:center;"><%= error %></p>
            <% } %>
            <% if (exito != null) { %>
                <p class="exito-msg" style="text-align:center;color:var(--blue-mid);font-weight:600;"><%= exito %></p>
            <% } %>

            <form method="post">
                <div class="form-row">
                    <div class="form-group">
                        <label>Nombre</label>
                        <div class="input-wrap">
                            <input type="text" name="nombre" required value="<%= esc(nombre) %>"/>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Especie</label>
                        <div class="input-wrap">
                            <select name="especie" id="selectEspecie" required class="select-input" onchange="actualizarRazas(this.value, null)">
                                <option value="">Selecciona una especie...</option>
                                <option value="Perro"   <%= "Perro".equals(especie)   ? "selected" : "" %>>Perro</option>
                                <option value="Gato"    <%= "Gato".equals(especie)    ? "selected" : "" %>>Gato</option>
                                <option value="Conejo"  <%= "Conejo".equals(especie)  ? "selected" : "" %>>Conejo</option>
                                <option value="Hámster" <%= "Hámster".equals(especie) ? "selected" : "" %>>Hámster</option>
                                <option value="Ave"     <%= "Ave".equals(especie)     ? "selected" : "" %>>Ave</option>
                                <option value="Pez"     <%= "Pez".equals(especie)     ? "selected" : "" %>>Pez</option>
                                <option value="Tortuga" <%= "Tortuga".equals(especie) ? "selected" : "" %>>Tortuga</option>
                            </select>
                        </div>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label>Raza</label>
                        <div class="input-wrap">
                            <select name="raza" id="selectRaza" required class="select-input">
                                <option value="">Primero selecciona una especie</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Edad</label>
                        <div class="input-wrap">
                            <input type="text" name="edad" required value="<%= esc(edad) %>"/>
                        </div>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label>Sexo</label>
                        <div class="input-wrap">
                            <select name="sexo" required class="select-input">
                                <option value="Macho"  <%= "Macho".equals(sexo)  ? "selected" : "" %>>Macho</option>
                                <option value="Hembra" <%= "Hembra".equals(sexo) ? "selected" : "" %>>Hembra</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Peso (kg)</label>
                        <div class="input-wrap">
                            <input type="number" step="0.01" name="peso" required value="<%= peso %>"/>
                        </div>
                    </div>
                </div>

                <button type="submit" class="btn-acceso">Guardar cambios</button>
            </form>

            <div class="links">
                <a href="${pageContext.request.contextPath}/tutor/listarMascotas.jsp">← Volver a mis mascotas</a>
            </div>
        </div>
    </div>

    <script>
    const RAZAS = {
        "Perro":   ["Labrador Retriever","Golden Retriever","Bulldog Francés","Beagle","Pastor Alemán","Chihuahua","Poodle","Yorkshire Terrier","Shih Tzu","Rottweiler","Mestizo"],
        "Gato":    ["Siamés","Persa","Maine Coon","Bengalí","Ragdoll","Sphynx","Británico de Pelo Corto","Mestizo"],
        "Conejo":  ["Holland Lop","Mini Rex","Angora","Nueva Zelanda","Mestizo"],
        "Hámster": ["Sirio","Ruso Enano","Roborovski"],
        "Ave":     ["Periquito","Canario","Loro","Cacatúa","Agapornis"],
        "Pez":     ["Goldfish","Betta","Guppy","Tetra Neón","Koi"],
        "Tortuga": ["Orejas Rojas","Griega","Mediterránea"]
    };
    function actualizarRazas(especie, seleccionada) {
        var sel = document.getElementById('selectRaza');
        sel.innerHTML = '';
        var razas = RAZAS[especie] || [];
        if (razas.length === 0) {
            sel.innerHTML = '<option value="">Selecciona una especie primero</option>';
            return;
        }
        razas.forEach(function(r) {
            var opt = document.createElement('option');
            opt.value = r; opt.textContent = r;
            if (seleccionada && r === seleccionada) opt.selected = true;
            sel.appendChild(opt);
        });
    }
    // Pre-cargar razas con la especie y raza actuales
    actualizarRazas("<%= esc(especie) %>", "<%= esc(raza) %>");
    </script>
</body>
</html>