<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String idStr = request.getParameter("id");
    if (idStr == null) {
        response.sendRedirect(request.getContextPath() + "/veterinario/productos.jsp");
        return;
    }
    int idProducto = Integer.parseInt(idStr);

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    if ("POST".equals(request.getMethod())) {
        PreparedStatement ps = con.prepareStatement("DELETE FROM productos WHERE id_producto=?");
        ps.setInt(1, idProducto);
        ps.executeUpdate();
        ps.close(); con.close();
        response.sendRedirect(request.getContextPath() + "/veterinario/productos.jsp?ok=3");
        return;
    }

    PreparedStatement ps = con.prepareStatement(
        "SELECT nombre FROM productos WHERE id_producto=?");
    ps.setInt(1, idProducto);
    ResultSet rs = ps.executeQuery();
    String nombre = "este producto";
    if (rs.next()) nombre = rs.getString("nombre");
    rs.close(); ps.close(); con.close();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Eliminar Producto – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">
    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/veterinario/productos.jsp" class="btn-back">← Volver</a>

        <div class="card" style="max-width:440px;padding:2rem;">
            <h2 class="card-title">Eliminar Producto</h2>
            <p style="color:var(--muted);text-align:center;margin-top:.5rem;">
                ¿Estás seguro de que deseas eliminar <strong style="color:var(--text);"><%= nombre %></strong>?
                Esta acción no se puede deshacer.
            </p>
            <div style="display:flex;gap:1rem;margin-top:1.8rem;justify-content:center;">
                <form method="post" action="?id=<%= idProducto %>">
                    <button type="submit" class="btn-del" style="padding:.7rem 1.8rem;">Sí, eliminar</button>
                </form>
                <a href="${pageContext.request.contextPath}/veterinario/productos.jsp"
                   class="btn-acceso" style="display:inline-block;width:auto;padding:.7rem 1.8rem;text-decoration:none;">
                    Cancelar
                </a>
            </div>
        </div>
    </div>
</body>
</html>
