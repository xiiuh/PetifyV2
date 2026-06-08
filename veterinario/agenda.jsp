<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String correo = request.getUserPrincipal().getName();
    String nomVete = correo;

    try {
        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();
        PreparedStatement ps = con.prepareStatement("SELECT nom_vete FROM veterinario WHERE correo = ?");
        ps.setString(1, correo);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) nomVete = rs.getString("nom_vete").replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
        rs.close(); ps.close(); con.close();
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel Veterinario – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">
    <div class="topbar">
        <span class="logo">PETIFY</span>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <p class="page-welcome">Bienvenido, <span><%= nomVete %></span></p>
        <p class="page-sub">Selecciona una opción para continuar</p>

        <div class="dashboard-grid">
            <a href="${pageContext.request.contextPath}/veterinario/productos.jsp" class="dash-card">
                <h3>Gestión de Productos</h3>
                <p>Registra, edita y elimina productos de la tienda</p>
            </a>
            <a href="${pageContext.request.contextPath}/veterinario/ventasPendientes.jsp" class="dash-card">
                <h3>Ventas Pendientes</h3>
                <p>Revisa y confirma las órdenes pendientes de recogida</p>
            </a>
            <a href="${pageContext.request.contextPath}/veterinario/historialVentas.jsp" class="dash-card">
                <h3>Historial de Ventas</h3>
                <p>Registro completo de todas las ventas realizadas</p>
            </a>
            <a href="${pageContext.request.contextPath}/veterinario/listarCitas.jsp" class="dash-card">
                <h3>Gestión de Citas</h3>
                <p>Agenda, consulta, modifica y cancela citas de pacientes</p>
            </a>
        </div>
    </div>
</body>
</html>
