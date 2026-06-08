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
        "SELECT id_vete FROM veterinario WHERE correo=?"
    );
    ps.setString(1, correo);

    ResultSet rs = ps.executeQuery();

    int idVete = 0;

    if(rs.next()){
        idVete = rs.getInt("id_vete");
    }

    rs.close();
    ps.close();
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Petify – Mis Citas</title>

    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../style.css">
</head>
<body class="dashboard">

<div class="topbar">
    <a href="${pageContext.request.contextPath}/veterinario/agenda.jsp" class="logo">PETIFY</a>
    <a href="../logout.jsp" class="btn-logout">Cerrar sesión</a>
</div>

<div class="main-content">

    <a href="agenda.jsp" class="btn-back">← Volver</a>

    <h2 class="page__title">Gestión de Citas</h2>
    <p class="page-sub">Consulta y administra tus citas</p>

    <div style="margin-bottom:1rem;">
        <a href="registrarCita.jsp"
           class="btn-acceso"
           style="display:inline-block;padding:10px 24px;text-decoration:none;">
            + Nueva cita
        </a>
    </div>

    <table class="tabla">

        <thead>
        <tr>
            <th>Tutor</th>
            <th>Mascota</th>
            <th>Fecha</th>
            <th>Hora</th>
            <th>Acciones</th>
        </tr>
        </thead>

        <tbody>

        <%
            ps = con.prepareStatement(
                "SELECT " +
                "c.id_citas," +
                "c.fecha," +
                "c.hora," +
                "t.nom_tutor AS tutor," +
                "m.nombre AS mascota " +
                "FROM citas c " +
                "JOIN tutor t ON c.id_tutor=t.id_tutor " +
                "JOIN mascota m ON c.id_mascota=m.id_mascota " +
                "WHERE c.id_vete=? " +
                "ORDER BY c.fecha,c.hora"
            );

            ps.setInt(1,idVete);

            rs = ps.executeQuery();

            boolean hayDatos = false;

            while(rs.next()){

                hayDatos = true;
        %>

        <tr>
            <td><%= esc(rs.getString("tutor")) %></td>
            <td><%= esc(rs.getString("mascota")) %></td>
            <td><%= rs.getString("fecha") %></td>
            <td><%= rs.getString("hora") %></td>

            <td>
                <a href="editarCita.jsp?id=<%= rs.getInt("id_citas") %>"
                   class="btn-edit">
                    Editar
                </a>

                <a href="eliminarCita.jsp?id=<%= rs.getInt("id_citas") %>"
                   class="btn-del"
                   onclick="return confirm('¿Eliminar esta cita?')">
                    Eliminar
                </a>
            </td>
        </tr>

        <%
            }

            rs.close();
            ps.close();
            con.close();

            if(!hayDatos){
        %>

        <tr>
            <td colspan="5"
                style="text-align:center;padding:2rem;color:var(--muted);">

                No tienes citas registradas.

            </td>
        </tr>

        <% } %>

        </tbody>

    </table>

</div>

</body>
</html>