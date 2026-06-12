<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement(
        "SELECT c.id_consulta, c.fecha_consulta, c.motivo, c.motivo_otro, c.peso, " +
        "       c.diagnostico, c.tratamiento, c.medicamentos, c.observaciones, " +
        "       m.nombre AS mascota, m.especie, v.nom_vete " +
        "FROM consultas c " +
        "JOIN mascota m ON c.id_mascota = m.id_mascota " +
        "JOIN tutor t ON m.id_tutor = t.id_tutor " +
        "JOIN veterinario v ON c.id_vete = v.id_vete " +
        "WHERE t.correo = ? " +
        "ORDER BY c.fecha_consulta DESC");
    ps.setString(1, correo);
    ResultSet rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Historial Clínico – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <style>
        .consulta-card {
            border:1.5px solid #eee;border-radius:14px;padding:1.3rem 1.5rem;
            margin-bottom:1rem;background:#fff;
        }
        .consulta-header {
            display:flex;justify-content:space-between;align-items:flex-start;
            flex-wrap:wrap;gap:.5rem;margin-bottom:.9rem;
        }
        .motivo-tag {
            font-size:.75rem;font-weight:600;padding:.25rem .75rem;
            border-radius:20px;background:#e8f5e9;color:#2e7d32;white-space:nowrap;
        }
        .field-label {
            font-size:.76rem;font-weight:600;color:var(--muted);
            text-transform:uppercase;letter-spacing:.04em;margin:.9rem 0 .3rem;
        }
        .text-block {
            background:var(--blue-pale,#f4f6fb);border-radius:9px;
            padding:.75rem 1rem;font-size:.9rem;line-height:1.6;
            overflow-wrap:break-word;word-break:break-word;white-space:pre-wrap;
        }
    </style>
</head>
<body class="dashboard">
    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/tutor/dashboard.jsp" class="btn-back">← Volver</a>
        <h2 class="page__title">Historial Clínico</h2>
        <p class="page-sub">Consultas veterinarias de tus mascotas</p>

        <%
            boolean hay = false;
            while (rs.next()) {
                hay = true;
                String fecha      = rs.getString("fecha_consulta");
                String motivo     = rs.getString("motivo");
                String mOtro      = rs.getString("motivo_otro");
                double pesoVal    = rs.getDouble("peso");
                boolean tienePeso = !rs.wasNull();
                String diag       = rs.getString("diagnostico");
                String trat       = rs.getString("tratamiento");
                String meds       = rs.getString("medicamentos");
                String obs        = rs.getString("observaciones");
                String mascota    = rs.getString("mascota");
                String especie    = rs.getString("especie");
                String vete       = rs.getString("nom_vete");
                String mLabel     = "Otro".equals(motivo) && mOtro != null ? esc(mOtro) : esc(motivo);
        %>
        <div class="consulta-card">
            <div class="consulta-header">
                <div>
                    <strong style="font-size:1rem;"><%= esc(mascota) %></strong>
                    <span style="font-size:.85rem;color:var(--muted);margin-left:.4rem;">(<%= esc(especie) %>)</span>
                    <div style="font-size:.82rem;color:var(--muted);margin-top:.2rem;">
                        <%= fecha != null ? fecha.substring(0,10) : "" %> &nbsp;·&nbsp; Dr. <%= esc(vete) %>
                        <% if (tienePeso) { %> &nbsp;·&nbsp; Peso: <strong><%= String.format("%.2f kg", pesoVal) %></strong><% } %>
                    </div>
                </div>
                <span class="motivo-tag"><%= mLabel %></span>
            </div>

            <% if (diag != null && !diag.trim().isEmpty()) { %>
                <p class="field-label">Diagnóstico</p>
                <div class="text-block"><%= esc(diag) %></div>
            <% } %>

            <% if (trat != null && !trat.trim().isEmpty()) { %>
                <p class="field-label">Tratamiento</p>
                <div class="text-block"><%= esc(trat) %></div>
            <% } %>

            <% if (meds != null && !meds.trim().isEmpty()) { %>
                <p class="field-label">Medicamentos</p>
                <div class="text-block"><%= esc(meds) %></div>
            <% } %>

            <% if (obs != null && !obs.trim().isEmpty()) { %>
                <p class="field-label">Observaciones</p>
                <div class="text-block"><%= esc(obs) %></div>
            <% } %>
        </div>
        <%
            }
            rs.close(); ps.close(); con.close();
            if (!hay) {
        %>
        <div style="text-align:center;padding:3rem 0;color:var(--muted);">
            Aún no hay consultas registradas para tus mascotas.
        </div>
        <% } %>
    </div>
</body>
</html>
