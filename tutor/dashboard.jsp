<%@ page import="java.sql.*, javax.naming.*,javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String correo = request.getUserPrincipal().getName();
    String nombreTutor = correo; 

    try {
        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        PreparedStatement ps = con.prepareStatement("SELECT nom_tutor FROM tutor WHERE correo = ?");
        ps.setString(1, correo);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) nombreTutor = rs.getString("nom_tutor");
        rs.close(); ps.close(); con.close();
    } catch (Exception e) {
        nombreTutor = correo;
    }
%>
<!DOCTYPE html>
<html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Panel del Tutor – Petify</title>
        <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    </head>
    <body class="dashboard">

        <div class="topbar">
            <span class="logo">PETIFY</span>
            <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesion</a>
        </div>

        <div class="main-content">
            <p class="page-welcome">Bienvenido, <span><%= nombreTutor %></span></p>
            <p class="page-sub">Selecciona una opcion para continuar</p>

            <div class="dashboard-grid">

                <a href="${pageContext.request.contextPath}/tutor/listarMascotas.jsp" class="dash-card">
                    <h3>Mis Mascotas</h3>
                    <p>Consulta, registra y gestiona tus mascotas</p>
                </a>

                <a href="${pageContext.request.contextPath}/tutor/listarCitas.jsp" class="dash-card">
                    <h3>Mis Citas</h3>
                    <p>Agenda, edita o cancela citas con el veterinario</p>
                </a>

                <a href="${pageContext.request.contextPath}/tienda.jsp" class="dash-card">
                    <h3>Tienda</h3>
                    <p>Consulta productos y gestiona tu carrito</p>
                </a>

            </div>
        </div>
    </body>
</html>