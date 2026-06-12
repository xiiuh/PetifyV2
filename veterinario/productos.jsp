<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String ok  = request.getParameter("ok");
    String msg = null;
    if ("1".equals(ok))      msg = "Producto registrado correctamente.";
    else if ("2".equals(ok)) msg = "Producto actualizado correctamente.";
    else if ("3".equals(ok)) msg = "Producto eliminado correctamente.";

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();
    PreparedStatement ps = con.prepareStatement(
        "SELECT id_producto, nombre, descripcion, cantidad, precio, imagen FROM productos ORDER BY nombre");
    ResultSet rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Productos – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">
    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:1rem;margin-bottom:1.5rem;">
            <h2 class="page__title" style="margin:0;">Gestión de Productos</h2>
            <a href="${pageContext.request.contextPath}/veterinario/registrarProducto.jsp"
               class="btn-acceso" style="display:inline-block;width:auto;padding:.6rem 1.4rem;text-decoration:none;">
                + Nuevo producto
            </a>
        </div>

        <% if (msg != null) { %>
            <p style="color:green;font-weight:600;margin-bottom:1rem;"><%= msg %></p>
        <% } %>

        <div class="card" style="padding:1.5rem;overflow-x:auto;">
            <table class="tabla">
                <thead>
                    <tr>
                        <th>Imagen</th>
                        <th>Nombre</th>
                        <th>Descripción</th>
                        <th>Precio</th>
                        <th>Stock</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    boolean hay = false;
                    while (rs.next()) {
                        hay = true;
                        int    id     = rs.getInt("id_producto");
                        String nom    = rs.getString("nombre");
                        String desc   = rs.getString("descripcion");
                        int    cant   = rs.getInt("cantidad");
                        double precio = rs.getDouble("precio");
                        String img    = rs.getString("imagen");
                %>
                <tr>
                    <td>
                        <% if (img != null && !img.isEmpty()) { %>
                            <img src="${pageContext.request.contextPath}/img/productos/<%= esc(img) %>"
                                 alt="<%= esc(nom) %>"
                                 style="width:54px;height:54px;object-fit:cover;border-radius:8px;"/>
                        <% } else { %>
                            <span style="color:var(--muted);font-size:.8rem;">Sin imagen</span>
                        <% } %>
                    </td>
                    <td><strong><%= esc(nom) %></strong></td>
                    <td style="font-size:.85rem;color:var(--muted);max-width:200px;"><%= esc(desc) %></td>
                    <td>$<%= String.format("%.2f", precio) %></td>
                    <td><%= cant %></td>
                    <td>
                        <div style="display:flex;gap:.4rem;">
                            <a href="${pageContext.request.contextPath}/veterinario/editarProducto.jsp?id=<%= id %>"
                               class="btn-edit">Editar</a>
                            <a href="${pageContext.request.contextPath}/veterinario/eliminarProducto.jsp?id=<%= id %>"
                               class="btn-del">Eliminar</a>
                        </div>
                    </td>
                </tr>
                <%
                    }
                    rs.close(); ps.close(); con.close();
                    if (!hay) {
                %>
                <tr>
                    <td colspan="6" style="text-align:center;color:var(--muted);padding:2rem;">
                        No hay productos registrados aún.
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
