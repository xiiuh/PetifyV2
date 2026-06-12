<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, java.util.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String idParam = request.getParameter("id");
    if (idParam == null) {
        response.sendRedirect(request.getContextPath() + "/veterinario/expedientes.jsp");
        return;
    }

    int idConsulta = Integer.parseInt(idParam);

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement(
        "SELECT c.*, m.nombre AS mascota, m.especie, m.raza, m.edad, m.sexo, " +
        "       t.nom_tutor, t.correo AS correo_tutor, t.telefono, " +
        "       v.nom_vete " +
        "FROM consultas c " +
        "JOIN mascota m ON c.id_mascota = m.id_mascota " +
        "JOIN tutor t ON m.id_tutor = t.id_tutor " +
        "JOIN veterinario v ON c.id_vete = v.id_vete " +
        "WHERE c.id_consulta = ?");
    ps.setInt(1, idConsulta);
    ResultSet rs = ps.executeQuery();

    if (!rs.next()) {
        rs.close(); ps.close(); con.close();
        response.sendRedirect(request.getContextPath() + "/veterinario/expedientes.jsp");
        return;
    }

    String fecha        = rs.getString("fecha_consulta");
    String motivo       = rs.getString("motivo");
    String motivoOtro   = rs.getString("motivo_otro");
    double pesoVal      = rs.getDouble("peso");
    boolean tienePeso   = !rs.wasNull();
    String diagnostico  = rs.getString("diagnostico");
    String tratamiento  = rs.getString("tratamiento");
    String medicamentos = rs.getString("medicamentos");
    String observaciones= rs.getString("observaciones");
    String mascota      = rs.getString("mascota");
    String especie      = rs.getString("especie");
    String raza         = rs.getString("raza");
    String edad         = rs.getString("edad");
    String sexo         = rs.getString("sexo");
    String nomTutor     = rs.getString("nom_tutor");
    String correoTutor  = rs.getString("correo_tutor");
    String telefonoT    = rs.getString("telefono");
    String nomVete      = rs.getString("nom_vete");
    int    idMascota    = rs.getInt("id_mascota");
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT c.id_consulta, c.fecha_consulta, c.motivo, c.motivo_otro " +
        "FROM consultas c " +
        "WHERE c.id_mascota = ? AND c.id_consulta != ? " +
        "ORDER BY c.fecha_consulta DESC LIMIT 5");
    ps.setInt(1, idMascota);
    ps.setInt(2, idConsulta);
    ResultSet rsH = ps.executeQuery();
    List<String[]> historial = new ArrayList<>();
    while (rsH.next()) {
        historial.add(new String[]{
            String.valueOf(rsH.getInt("id_consulta")),
            rsH.getString("fecha_consulta"),
            rsH.getString("motivo"),
            rsH.getString("motivo_otro")
        });
    }
    rsH.close(); ps.close(); con.close();

    String motivoLabel = "Otro".equals(motivo) && motivoOtro != null ? esc(motivoOtro) : esc(motivo);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Consulta #<%= idConsulta %> – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <style>
        .info-grid { display:grid;grid-template-columns:1fr 1fr;gap:1rem; }
        .info-item label { font-size:.78rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.04em;display:block;margin-bottom:.2rem; }
        .info-item p { margin:0;font-size:.95rem; }
        .section-title { font-size:.78rem;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.06em;margin:1.5rem 0 .7rem;border-top:1px solid #eee;padding-top:1rem; }
        .text-block { background:var(--blue-pale,#f4f6fb);border-radius:10px;padding:.85rem 1rem;font-size:.92rem;line-height:1.6;white-space:pre-wrap;overflow-wrap:break-word;word-break:break-word; }
        .empty-field { color:var(--muted);font-style:italic;font-size:.88rem;margin:0; }
        @media(max-width:520px){ .info-grid{grid-template-columns:1fr;} }
    </style>
</head>
<body class="dashboard">
    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/veterinario/expedientes.jsp" class="btn-back">← Volver a expedientes</a>

        <div style="display:flex;gap:1.5rem;flex-wrap:wrap;align-items:flex-start;margin-top:1rem;">

            <div class="card" style="flex:1;min-width:300px;padding:1.8rem;">
                <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:.5rem;margin-bottom:1rem;">
                    <div>
                        <h2 class="card-title" style="margin:0;">Consulta #<%= idConsulta %></h2>
                        <p style="margin:.3rem 0 0;font-size:.87rem;color:var(--muted);">
                            <%= fecha != null ? fecha.substring(0, 10) : "" %> &nbsp;·&nbsp; Dr. <%= esc(nomVete) %>
                        </p>
                    </div>
                    <span style="background:#e8f5e9;color:#2e7d32;font-size:.8rem;font-weight:600;padding:.25rem .8rem;border-radius:20px;white-space:nowrap;">
                        <%= motivoLabel %>
                    </span>
                </div>

                <p class="section-title" style="border-top:none;padding-top:0;margin-top:.5rem;">Paciente</p>
                <div class="info-grid">
                    <div class="info-item"><label>Mascota</label><p><%= esc(mascota) %> (<%= esc(especie) %>)</p></div>
                    <div class="info-item"><label>Raza</label><p><%= esc(raza) %></p></div>
                    <div class="info-item"><label>Edad</label><p><%= esc(edad) %></p></div>
                    <div class="info-item"><label>Sexo</label><p><%= esc(sexo) %></p></div>
                    <div class="info-item"><label>Peso en consulta</label><p><%= tienePeso ? String.format("%.2f kg", pesoVal) : "—" %></p></div>
                </div>

                <p class="section-title">Dueño</p>
                <div class="info-grid">
                    <div class="info-item"><label>Nombre</label><p><%= esc(nomTutor) %></p></div>
                    <div class="info-item"><label>Teléfono</label><p><%= esc(telefonoT) %></p></div>
                    <div class="info-item" style="grid-column:span 2"><label>Correo</label><p><%= esc(correoTutor) %></p></div>
                </div>

                <p class="section-title">Diagnóstico</p>
                <% if (diagnostico != null && !diagnostico.trim().isEmpty()) { %>
                    <div class="text-block"><%= esc(diagnostico) %></div>
                <% } else { %><p class="empty-field">Sin diagnóstico registrado.</p><% } %>

                <p class="section-title">Tratamiento</p>
                <% if (tratamiento != null && !tratamiento.trim().isEmpty()) { %>
                    <div class="text-block"><%= esc(tratamiento) %></div>
                <% } else { %><p class="empty-field">Sin tratamiento registrado.</p><% } %>

                <p class="section-title">Medicamentos</p>
                <% if (medicamentos != null && !medicamentos.trim().isEmpty()) { %>
                    <div class="text-block"><%= esc(medicamentos) %></div>
                <% } else { %><p class="empty-field">Sin medicamentos registrados.</p><% } %>

                <p class="section-title">Observaciones</p>
                <% if (observaciones != null && !observaciones.trim().isEmpty()) { %>
                    <div class="text-block"><%= esc(observaciones) %></div>
                <% } else { %><p class="empty-field">Sin observaciones.</p><% } %>
            </div>

            <% if (!historial.isEmpty()) { %>
            <div class="card" style="width:240px;flex-shrink:0;padding:1.4rem;">
                <h3 style="margin:0 0 1rem;font-size:.93rem;font-weight:700;">Otras consultas de <%= esc(mascota) %></h3>
                <div style="display:flex;flex-direction:column;gap:.6rem;">
                <% for (String[] h : historial) {
                    String hLabel = "Otro".equals(h[2]) && h[3] != null ? esc(h[3]) : esc(h[2]);
                %>
                    <a href="${pageContext.request.contextPath}/veterinario/detalleConsulta.jsp?id=<%= h[0] %>"
                       style="display:block;padding:.7rem .9rem;background:var(--blue-pale,#f4f6fb);border-radius:10px;text-decoration:none;color:var(--text);">
                        <span style="font-size:.78rem;color:var(--muted);display:block;"><%= h[1] != null ? h[1].substring(0,10) : "" %></span>
                        <span style="font-size:.88rem;font-weight:500;"><%= hLabel %></span>
                    </a>
                <% } %>
                </div>
            </div>
            <% } %>

        </div>
    </div>
</body>
</html>
