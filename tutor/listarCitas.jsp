<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    Context ctx = new javax.naming.InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement("SELECT id_tutor FROM tutor WHERE correo = ?");
    ps.setString(1, correo);
    ResultSet rs = ps.executeQuery();
    int idTutor = 0;
    if (rs.next()) idTutor = rs.getInt("id_tutor");
    rs.close(); ps.close();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <title>Petify – Mis Citas</title>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="../style.css"/>
</head>
<body class="dashboard">

  <div class="topbar">
    <a href="${pageContext.request.contextPath}/tutor/dashboard.jsp" class="logo">PETIFY</a>
    <a href="../logout.jsp" class="btn-logout">Cerrar sesión</a>
  </div>

  <div class="main-content">
    <a href="dashboard.jsp" class="btn-back">← Volver</a>
    <h2 class="page__title">Mis Citas</h2>
    <p class="page-sub">Historial y próximas citas agendadas</p>

    <div style="margin-bottom: 1rem;">
      <a href="registrarCita.jsp" class="btn-acceso" style="display:inline-block; padding: 10px 24px; text-decoration:none;">
        + Nueva cita
      </a>
    </div>

    <table class="tabla">
      <thead>
        <tr>
          <th>Mascota</th>
          <th>Veterinario</th>
          <th>Fecha</th>
          <th>Hora</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody>
        <%
          ps = con.prepareStatement(
            "SELECT c.id_citas, c.fecha, c.hora, " +
            "m.nombre AS mascota, v.nom_vete AS veterinario " +
            "FROM citas c " +
            "JOIN mascota m ON c.id_mascota = m.id_mascota " +
            "JOIN veterinario v ON c.id_vete = v.id_vete " +
            "WHERE c.id_tutor = ? " +
            "ORDER BY c.fecha, c.hora"
          );
          ps.setInt(1, idTutor);
          rs = ps.executeQuery();

          boolean hayCitas = false;
          while (rs.next()) {
              hayCitas = true;
        %>
        <tr>
          <td><%= esc(rs.getString("mascota")) %></td>
          <td><%= esc(rs.getString("veterinario")) %></td>
          <td><%= rs.getString("fecha") %></td>
          <td><%= rs.getString("hora") %></td>
          <td>
            <a href="editarCita.jsp?id=<%= rs.getInt("id_citas") %>" class="btn-edit">Editar</a>
            <a href="eliminarCita.jsp?id=<%= rs.getInt("id_citas") %>" class="btn-del"
               onclick="return confirm('¿Eliminar esta cita?')">Eliminar</a>
          </td>
        </tr>
        <%
          }
          rs.close(); ps.close(); con.close();

          if (!hayCitas) {
        %>
        <tr>
          <td colspan="5" style="text-align:center; color: var(--muted); padding: 2rem;">
            No tienes citas agendadas aún.
          </td>
        </tr>
        <% } %>
      </tbody>
    </table>
  </div>

</body>
</html>