<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, java.util.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo    = request.getUserPrincipal().getName();
    String error     = null;
    String idCitaStr = request.getParameter("id_cita");
    String idMascotaPreStr = request.getParameter("id_mascota");
    Integer idCitaParam    = null;
    Integer idMascotaPre   = null;
    try { if (idCitaStr != null)      idCitaParam  = Integer.parseInt(idCitaStr); } catch (Exception ignored) {}
    try { if (idMascotaPreStr != null) idMascotaPre = Integer.parseInt(idMascotaPreStr); } catch (Exception ignored) {}

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement("SELECT id_vete FROM veterinario WHERE correo = ?");
    ps.setString(1, correo);
    ResultSet rs = ps.executeQuery();
    int idVete = 0;
    if (rs.next()) idVete = rs.getInt("id_vete");
    rs.close(); ps.close();

    if ("POST".equals(request.getMethod())) {
        try {
            int    idMascota   = Integer.parseInt(request.getParameter("id_mascota"));
            String motivo      = request.getParameter("motivo");
            String motivoOtro  = "Otro".equals(motivo) ? request.getParameter("motivo_otro") : null;
            String pesoStr     = request.getParameter("peso");
            Double peso        = (pesoStr != null && !pesoStr.trim().isEmpty()) ? Double.parseDouble(pesoStr) : null;
            String diagnostico = request.getParameter("diagnostico");
            String tratamiento = request.getParameter("tratamiento");
            String medicamentos= request.getParameter("medicamentos");
            String observaciones=request.getParameter("observaciones");

            PreparedStatement ins = con.prepareStatement(
                "INSERT INTO consultas (id_mascota, id_vete, id_cita, motivo, motivo_otro, peso, diagnostico, tratamiento, medicamentos, observaciones) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            ins.setInt(1, idMascota);
            ins.setInt(2, idVete);
            String idCitaPost = request.getParameter("id_cita_hidden");
            if (idCitaPost != null && !idCitaPost.isEmpty()) ins.setInt(3, Integer.parseInt(idCitaPost));
            else ins.setNull(3, java.sql.Types.INTEGER);
            ins.setString(4, motivo);
            ins.setString(5, motivoOtro);
            if (peso != null) ins.setDouble(6, peso); else ins.setNull(6, java.sql.Types.DECIMAL);
            ins.setString(7, diagnostico);
            ins.setString(8, tratamiento);
            ins.setString(9, medicamentos);
            ins.setString(10, observaciones);
            ins.executeUpdate();
            ins.close(); con.close();

            response.sendRedirect(request.getContextPath() + "/veterinario/expedientes.jsp?ok=1");
            return;
        } catch (Exception e) {
            error = "Error al guardar la consulta. Intenta de nuevo.";
        }
    }

    ps = con.prepareStatement(
        "SELECT m.id_mascota, m.nombre, m.especie, t.nom_tutor " +
        "FROM mascota m JOIN tutor t ON m.id_tutor = t.id_tutor " +
        "ORDER BY t.nom_tutor, m.nombre");
    rs = ps.executeQuery();
    List<String[]> mascotas = new ArrayList<>();
    while (rs.next()) {
        mascotas.add(new String[]{
            String.valueOf(rs.getInt("id_mascota")),
            rs.getString("nombre"),
            rs.getString("especie"),
            rs.getString("nom_tutor")
        });
    }
    rs.close(); ps.close(); con.close();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nueva Consulta – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <style>
        .textarea-field {
            width:100%;background:var(--blue-pale);border:2px solid transparent;
            border-radius:12px;padding:11px 16px;font-family:'DM Sans',sans-serif;
            font-size:.94rem;color:var(--text);outline:none;resize:vertical;box-sizing:border-box;
        }
        .textarea-field:focus { border-color:#1a3d35; }
        .select-field {
            width:100%;background:var(--blue-pale);border:2px solid transparent;
            border-radius:12px;padding:11px 16px;font-family:'DM Sans',sans-serif;
            font-size:.94rem;color:var(--text);outline:none;appearance:none;cursor:pointer;
        }
        .select-field:focus { border-color:#1a3d35; }
    </style>
</head>
<body class="dashboard">
    <div class="topbar">
        <a href="${pageContext.request.contextPath}/veterinario/agenda.jsp" class="logo">PETIFY</a>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/veterinario/expedientes.jsp" class="btn-back">← Volver</a>

        <div class="card card--register" style="max-width:620px;">
            <h2 class="card-title">Nueva Consulta</h2>

            <% if (error != null) { %>
                <p class="error-msg" style="text-align:center;"><%= error %></p>
            <% } %>

            <form method="post">
                <input type="hidden" name="id_cita_hidden" value="<%= idCitaParam != null ? idCitaParam : "" %>"/>

                <% if (idCitaParam != null) { %>
                <p style="background:#e8f5e9;color:#2e7d32;border-radius:10px;padding:.6rem 1rem;margin-bottom:1rem;font-size:.9rem;font-weight:500;">
                    Vinculada a la cita #<%= idCitaParam %>
                </p>
                <% } %>

                <div class="form-group">
                    <label>Mascota <span class="required">*</span></label>
                    <select name="id_mascota" required class="select-field">
                        <option value="">Selecciona una mascota...</option>
                        <% for (String[] m : mascotas) {
                            boolean preSelected = idMascotaPre != null && idMascotaPre == Integer.parseInt(m[0]);
                        %>
                            <option value="<%= m[0] %>" <%= preSelected ? "selected" : "" %>><%= esc(m[3]) %> — <%= esc(m[1]) %> (<%= esc(m[2]) %>)</option>
                        <% } %>
                    </select>
                </div>

                <div class="form-row" style="margin-top:.9rem;">
                    <div class="form-group">
                        <label>Motivo de visita <span class="required">*</span></label>
                        <select name="motivo" required class="select-field" id="selectMotivo" onchange="toggleOtro(this)">
                            <option value="">Selecciona...</option>
                            <option value="Revisión general">Revisión general</option>
                            <option value="Vacunación">Vacunación</option>
                            <option value="Desparasitación">Desparasitación</option>
                            <option value="Enfermedad / malestar">Enfermedad / malestar</option>
                            <option value="Urgencia">Urgencia</option>
                            <option value="Cirugía">Cirugía</option>
                            <option value="Seguimiento">Seguimiento</option>
                            <option value="Otro">Otro</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Peso (kg)</label>
                        <div class="input-wrap">
                            <input type="number" name="peso" step="0.01" min="0" placeholder="Ej. 8.50"/>
                        </div>
                    </div>
                </div>

                <div class="form-group" id="campoOtro" style="margin-top:.9rem;display:none;">
                    <label>Especifica el motivo <span class="required">*</span></label>
                    <div class="input-wrap">
                        <input type="text" name="motivo_otro" id="inputOtro" placeholder="Describe el motivo..."/>
                    </div>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Diagnóstico</label>
                    <textarea name="diagnostico" rows="3" class="textarea-field" placeholder="Describe el diagnóstico..."></textarea>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Tratamiento</label>
                    <textarea name="tratamiento" rows="3" class="textarea-field" placeholder="Tratamiento indicado..."></textarea>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Medicamentos</label>
                    <textarea name="medicamentos" rows="2" class="textarea-field" placeholder="Medicamentos recetados..."></textarea>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Observaciones</label>
                    <textarea name="observaciones" rows="3" class="textarea-field" placeholder="Notas adicionales..."></textarea>
                </div>

                <button type="submit" class="btn-acceso" style="margin-top:1.4rem;">Guardar consulta</button>
            </form>
        </div>
    </div>

    <script>
        function toggleOtro(select) {
            var campo = document.getElementById('campoOtro');
            var input = document.getElementById('inputOtro');
            if (select.value === 'Otro') {
                campo.style.display = 'block';
                input.required = true;
            } else {
                campo.style.display = 'none';
                input.required = false;
            }
        }
    </script>
</body>
</html>
