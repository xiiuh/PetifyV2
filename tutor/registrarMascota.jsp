<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String correo = request.getUserPrincipal().getName();
    int idTutor = 0;

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement psId = con.prepareStatement("SELECT id_tutor FROM tutor WHERE correo = ?");
    psId.setString(1, correo);
    ResultSet rsId = psId.executeQuery();
    if (rsId.next()) idTutor = rsId.getInt("id_tutor");
    rsId.close(); psId.close();

    String error = null;

    if ("POST".equals(request.getMethod())) {

    String nombre  = request.getParameter("nombre");
    String especie = request.getParameter("especie");
    String raza    = request.getParameter("raza");
    String edad    = request.getParameter("edad");
    String sexo    = request.getParameter("sexo");
    String peso    = request.getParameter("peso");

    nombre  = nombre  != null ? nombre.trim()  : "";
    especie = especie != null ? especie.trim() : "";
    raza    = raza    != null ? raza.trim()    : "";
    edad    = edad    != null ? edad.trim()    : "";
    peso    = peso    != null ? peso.trim()    : "";

    if (nombre.isEmpty() || especie.isEmpty() || raza.isEmpty() || edad.isEmpty()) {
        error = "Todos los campos son obligatorios.";
    } else {
        try {
            double pesoVal = Double.parseDouble(peso);
            if (pesoVal <= 0) throw new Exception("El peso debe ser mayor a 0.");
            if (idTutor <= 0) throw new Exception("No existe el tutor.");

            PreparedStatement psIns = con.prepareStatement(
                "INSERT INTO mascota (nombre, especie, raza, edad, sexo, peso, id_tutor) VALUES (?,?,?,?,?,?,?)"
            );

            psIns.setString(1, nombre);
            psIns.setString(2, especie);
            psIns.setString(3, raza);
            psIns.setString(4, edad);
            psIns.setString(5, sexo);
            psIns.setDouble(6, pesoVal);
            psIns.setInt(7, idTutor);

            psIns.executeUpdate();
            psIns.close();
            con.close();

            response.sendRedirect(request.getContextPath() + "/tutor/listarMascotas.jsp");
            return;

        } catch (NumberFormatException nfe) {
            error = "El peso debe ser un número válido.";
        } catch (Exception e) {
            error = "Error interno al registrar la mascota.";
            System.err.println("[registrarMascota] " + e);
        }
    }
}
    con.close();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registrar Mascota – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
    <body class="dashboard">
        <jsp:include page="/nav.jsp"/>

        <div class="main-content">
            <a href="${pageContext.request.contextPath}/tutor/listarMascotas.jsp" class="btn-back">Volver a mis mascotas</a>
            
            <div class="card card--register">
                <h2 class="card-title">Registrar Mascota</h2>

                <% if (error != null) { %>
                    <p class="error-msg" style="text-align:center;"><%= error %></p>
                <% } %>

                <form method="post">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Nombre</label>
                            <div class="input-wrap">
                                <input type="text" name="nombre" required placeholder="Nombre de la mascota"/>
                            </div>
                        </div>
                        <div class="form-group">
                            <label>Especie</label>
                            <div class="input-wrap">
                                <select name="especie" id="selectEspecie" required class="select-input" onchange="actualizarRazas(this.value)">
                                    <option value="">Selecciona una especie...</option>
                                    <option value="Perro">Perro</option>
                                    <option value="Gato">Gato</option>
                                    <option value="Conejo">Conejo</option>
                                    <option value="Hámster">Hámster</option>
                                    <option value="Ave">Ave</option>
                                    <option value="Pez">Pez</option>
                                    <option value="Tortuga">Tortuga</option>
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
                                <input type="text" name="edad" required placeholder="Ej: 2 años"/>
                            </div>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label>Sexo</label>
                            <div class="input-wrap">
                                <select name="sexo" required class="select-input">
                                    <option value="Macho">Macho</option>
                                    <option value="Hembra">Hembra</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label>Peso (kg)</label>
                            <div class="input-wrap">
                                <input type="number" step="0.01" name="peso" required placeholder="Ej: 4.5"/>
                            </div>
                        </div>
                    </div>

                    <button type="submit" class="btn-acceso">Registrar</button>
                </form>

                <div class="links">
                    <a href="${pageContext.request.contextPath}/tutor/listarMascotas.jsp">Volver a mis mascotas</a>
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
    </script>
    </body>
</html>