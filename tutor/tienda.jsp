<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, java.util.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();

    HashMap<Integer, Integer> carrito = (HashMap<Integer, Integer>) session.getAttribute("carrito");
    if (carrito == null) {
        carrito = new HashMap<>();
        session.setAttribute("carrito", carrito);
    }

    if ("POST".equals(request.getMethod()) && "agregar".equals(request.getParameter("accion"))) {
        String idStr  = request.getParameter("id_producto");
        String canStr = request.getParameter("cantidad");
        if (idStr != null && canStr != null) {
            try {
                int id  = Integer.parseInt(idStr);
                int can = Math.max(1, Integer.parseInt(canStr));
                carrito.merge(id, can, Integer::sum);
            } catch (NumberFormatException ignored) {}
        }
        response.sendRedirect(request.getContextPath() + "/tutor/tienda.jsp");
        return;
    }

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement ps = con.prepareStatement("SELECT nom_tutor FROM tutor WHERE correo = ?");
    ps.setString(1, correo);
    ResultSet rs = ps.executeQuery();
    String nomTutor = correo;
    if (rs.next()) nomTutor = rs.getString("nom_tutor");
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT id_producto, nombre, descripcion, cantidad, precio FROM productos WHERE cantidad > 0"
    );
    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tienda – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">

    <div class="topbar">
        <span class="logo">PETIFY</span>
        <span class="user-welcome">Hola, <%= nomTutor %></span>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:1rem;margin-bottom:1.5rem;">
            <a href="${pageContext.request.contextPath}/tutor/dashboard.jsp" class="btn-back" style="margin:0;">← Volver</a>
            <a href="${pageContext.request.contextPath}/tutor/carritoCompras.jsp"
               class="btn-acceso"
               style="display:inline-block;width:auto;padding:.6rem 1.4rem;text-decoration:none;">
                Carrito (<%= carrito.size() %> producto<%= carrito.size() != 1 ? "s" : "" %>)
            </a>
        </div>

        <h2 class="page__title">Tienda</h2>
        <p class="page-sub">Productos disponibles para tu mascota</p>

        <div class="dashboard-grid" style="margin-top:1.5rem;">
        <%
            boolean hayProductos = false;
            while (rs.next()) {
                hayProductos = true;
                int    idProd  = rs.getInt("id_producto");
                String nombre  = rs.getString("nombre");
                String desc    = rs.getString("descripcion");
                int    stock   = rs.getInt("cantidad");
                double precio  = rs.getDouble("precio");
        %>
            <div class="dash-card" style="display:flex;flex-direction:column;gap:.75rem;">
                <h3><%= nombre %></h3>
                <% if (desc != null && !desc.isEmpty()) { %>
                    <p style="font-size:.85rem;color:var(--muted);margin:0;"><%= desc %></p>
                <% } %>
                <p style="font-size:1.1rem;font-weight:700;margin:0;">$<%= String.format("%.2f", precio) %></p>
                <p style="font-size:.8rem;color:var(--muted);margin:0;">Stock: <%= stock %></p>
                <form method="post" style="display:flex;gap:.5rem;align-items:center;margin-top:auto;">
                    <input type="hidden" name="accion"      value="agregar"/>
                    <input type="hidden" name="id_producto" value="<%= idProd %>"/>
                    <input type="number" name="cantidad" value="1" min="1" max="<%= stock %>"
                           style="width:65px;padding:.4rem .5rem;border:1px solid var(--border);border-radius:8px;font-size:.9rem;"/>
                    <button type="submit" class="btn-acceso"
                            style="padding:.4rem 1rem;width:auto;font-size:.85rem;">
                        Agregar
                    </button>
                </form>
            </div>
        <%
            }
            rs.close(); ps.close(); con.close();
            if (!hayProductos) {
        %>
            <p style="color:var(--muted);">No hay productos disponibles en este momento.</p>
        <%
            }
        %>
        </div>
    </div>
</body>
</html>
