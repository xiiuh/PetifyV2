<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String busqueda = request.getParameter("q");
    if (busqueda == null) busqueda = "";

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps;
    if (busqueda.isEmpty()) {
        ps = con.prepareStatement(
            "SELECT c.id_consulta, c.fecha_consulta, c.motivo, c.motivo_otro, c.peso, " +
            "       m.nombre AS mascota, m.especie, t.nom_tutor " +
            "FROM consultas c " +
            "JOIN mascota m ON c.id_mascota = m.id_mascota " +
            "JOIN tutor t ON m.id_tutor = t.id_tutor " +
            "ORDER BY c.fecha_consulta DESC");
    } else {
        ps = con.prepareStatement(
            "SELECT c.id_consulta, c.fecha_consulta, c.motivo, c.motivo_otro, c.peso, " +
            "       m.nombre AS mascota, m.especie, t.nom_tutor " +
            "FROM consultas c " +
            "JOIN mascota m ON c.id_mascota = m.id_mascota " +
            "JOIN tutor t ON m.id_tutor = t.id_tutor " +
            "WHERE t.nom_tutor LIKE ? OR m.nombre LIKE ? " +
            "ORDER BY c.fecha_consulta DESC");
        String like = "%" + busqueda + "%";
        ps.setString(1, like);
        ps.setString(2, like);
    }

    ResultSet rs = ps.executeQuery();
    boolean guardado = "1".equals(request.getParameter("ok"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Expedientes – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">
    <div class="topbar">
        <a href="${pageContext.request.contextPath}/veterinario/agenda.jsp" class="logo">PETIFY</a>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:1rem;margin-bottom:1.5rem;">
            <div>
                <a href="${pageContext.request.contextPath}/veterinario/agenda.jsp" class="btn-back" style="margin:0 0 .5rem;">← Volver</a>
                <h2 class="page__title" style="margin:.5rem 0 0;">Expedientes Clínicos</h2>
            </div>
            <a href="${pageContext.request.contextPath}/veterinario/registrarConsulta.jsp"
               class="btn-acceso" style="display:inline-block;width:auto;padding:.6rem 1.4rem;text-decoration:none;">
                + Nueva consulta
            </a>
        </div>

        <% if (guardado) { %>
        <p style="background:#e8f5e9;color:#2e7d32;border-radius:10px;padding:.75rem 1rem;margin-bottom:1.2rem;font-weight:500;">
            Consulta registrada correctamente.
        </p>
        <% } %>

        <form method="get" style="margin-bottom:1.2rem;display:flex;gap:.5rem;align-items:center;max-width:460px;">
            <div class="input-wrap" style="flex:1;">
                <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
                </svg>
                <input type="text" name="q" value="<%= esc(busqueda) %>"
                       placeholder="Buscar por dueño o mascota..."/>
            </div>
            <button type="submit" class="btn-acceso" style="width:auto;padding:.6rem 1.2rem;">Buscar</button>
            <% if (!busqueda.isEmpty()) { %>
                <a href="expedientes.jsp" style="font-size:.85rem;color:var(--muted);text-decoration:none;">Limpiar</a>
            <% } %>
        </form>

        <div class="card" style="padding:1.5rem;overflow-x:auto;">
            <table class="tabla">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Fecha</th>
                        <th>Dueño</th>
                        <th>Mascota</th>
                        <th>Motivo</th>
                        <th>Peso</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <%
                    boolean hay = false;
                    while (rs.next()) {
                        hay = true;
                        int    id       = rs.getInt("id_consulta");
                        String fecha    = rs.getString("fecha_consulta");
                        String tutor    = rs.getString("nom_tutor");
                        String mascota  = rs.getString("mascota");
                        String especie  = rs.getString("especie");
                        String motivo   = rs.getString("motivo");
                        String mOtro    = rs.getString("motivo_otro");
                        double pesoVal  = rs.getDouble("peso");
                        boolean tienePeso = !rs.wasNull();
                        String motivoLabel = "Otro".equals(motivo) && mOtro != null ? esc(mOtro) : esc(motivo);
                %>
                <tr>
                    <td><strong>#<%= id %></strong></td>
                    <td style="font-size:.85rem;"><%= fecha != null ? fecha.substring(0, 10) : "" %></td>
                    <td><strong><%= esc(tutor) %></strong></td>
                    <td><%= esc(mascota) %> <span style="font-size:.8rem;color:var(--muted);">(<%= esc(especie) %>)</span></td>
                    <td><%= motivoLabel %></td>
                    <td><%= tienePeso ? String.format("%.1f kg", pesoVal) : "—" %></td>
                    <td>
                        <a href="${pageContext.request.contextPath}/veterinario/detalleConsulta.jsp?id=<%= id %>" class="btn-edit">Ver</a>
                    </td>
                </tr>
                <%
                    }
                    rs.close(); ps.close(); con.close();
                    if (!hay) {
                %>
                <tr>
                    <td colspan="7" style="text-align:center;color:var(--muted);padding:2rem;">
                        <%= busqueda.isEmpty() ? "No hay consultas registradas." : "No se encontraron resultados para &quot;" + esc(busqueda) + "&quot;." %>
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
