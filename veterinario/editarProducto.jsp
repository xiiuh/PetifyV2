<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, javax.servlet.http.*, java.io.*, java.nio.file.*" %>
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
    String error = null;

    if ("POST".equals(request.getMethod())) {
        String nombre      = request.getParameter("nombre");
        String descripcion = request.getParameter("descripcion");
        String precioStr   = request.getParameter("precio");
        String cantStr     = request.getParameter("cantidad");

        try {
            double precio   = Double.parseDouble(precioStr);
            int    cantidad = Integer.parseInt(cantStr);

            Context ctx2 = new InitialContext();
            DataSource ds2 = (DataSource) ctx2.lookup("java:comp/env/jdbc/petify");
            Connection con2 = ds2.getConnection();

            Part filePart = request.getPart("imagen");
            if (filePart != null && filePart.getSize() > 0) {
                String submitted = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                String ext = submitted.contains(".") ? submitted.substring(submitted.lastIndexOf('.')) : "";
                String imagenNombre = System.currentTimeMillis() + ext;
                String uploadDir = "C:/petify_uploads/productos";
                new File(uploadDir).mkdirs();
                filePart.write(uploadDir + File.separator + imagenNombre);

                PreparedStatement ps2 = con2.prepareStatement(
                    "UPDATE productos SET nombre=?, descripcion=?, cantidad=?, precio=?, imagen=? WHERE id_producto=?");
                ps2.setString(1, nombre); ps2.setString(2, descripcion);
                ps2.setInt(3, cantidad);  ps2.setDouble(4, precio);
                ps2.setString(5, imagenNombre); ps2.setInt(6, idProducto);
                ps2.executeUpdate(); ps2.close();
            } else {
                PreparedStatement ps2 = con2.prepareStatement(
                    "UPDATE productos SET nombre=?, descripcion=?, cantidad=?, precio=? WHERE id_producto=?");
                ps2.setString(1, nombre); ps2.setString(2, descripcion);
                ps2.setInt(3, cantidad);  ps2.setDouble(4, precio);
                ps2.setInt(5, idProducto);
                ps2.executeUpdate(); ps2.close();
            }
            con2.close();
            response.sendRedirect(request.getContextPath() + "/veterinario/productos.jsp?ok=2");
            return;
        } catch (Exception e) {
            error = "Error al actualizar: " + e.getMessage();
        }
    }

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();
    PreparedStatement ps = con.prepareStatement(
        "SELECT nombre, descripcion, cantidad, precio, imagen FROM productos WHERE id_producto=?");
    ps.setInt(1, idProducto);
    ResultSet rs = ps.executeQuery();
    if (!rs.next()) {
        rs.close(); ps.close(); con.close();
        response.sendRedirect(request.getContextPath() + "/veterinario/productos.jsp");
        return;
    }
    String pNombre      = rs.getString("nombre");
    String pDescripcion = rs.getString("descripcion");
    int    pCantidad    = rs.getInt("cantidad");
    double pPrecio      = rs.getDouble("precio");
    String pImagen      = rs.getString("imagen");
    rs.close(); ps.close(); con.close();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Editar Producto – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">
    <div class="topbar">
        <span class="logo">PETIFY</span>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/veterinario/productos.jsp" class="btn-back">← Volver</a>

        <div class="card card--register" style="max-width:560px;">
            <h2 class="card-title">Editar Producto</h2>

            <% if (error != null) { %>
                <p class="error-msg" style="text-align:center;"><%= error %></p>
            <% } %>

            <form method="post" enctype="multipart/form-data" action="?id=<%= idProducto %>">

                <div class="form-group">
                    <label>Nombre <span class="required">*</span></label>
                    <div class="input-wrap">
                        <input type="text" name="nombre" required value="<%= pNombre %>"/>
                    </div>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Descripción</label>
                    <textarea name="descripcion" rows="3"
                              style="width:100%;background:var(--blue-pale);border:2px solid transparent;
                                     border-radius:12px;padding:11px 16px;font-family:'DM Sans',sans-serif;
                                     font-size:.94rem;color:var(--text);outline:none;resize:vertical;"><%= pDescripcion != null ? pDescripcion : "" %></textarea>
                </div>

                <div class="form-row" style="margin-top:.9rem;">
                    <div class="form-group">
                        <label>Precio ($) <span class="required">*</span></label>
                        <div class="input-wrap">
                            <input type="number" name="precio" step="0.01" min="0" required value="<%= pPrecio %>"/>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Cantidad en stock <span class="required">*</span></label>
                        <div class="input-wrap">
                            <input type="number" name="cantidad" min="0" required value="<%= pCantidad %>"/>
                        </div>
                    </div>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Imagen del producto</label>
                    <% if (pImagen != null && !pImagen.isEmpty()) { %>
                        <img src="${pageContext.request.contextPath}/img/productos/<%= pImagen %>"
                             alt="imagen actual"
                             style="display:block;max-height:120px;margin-bottom:.6rem;border-radius:10px;object-fit:cover;"/>
                        <p style="font-size:.78rem;color:var(--muted);margin-bottom:.4rem;">
                            Deja vacío para conservar la imagen actual.
                        </p>
                    <% } %>
                    <input type="file" name="imagen" accept="image/*"
                           style="width:100%;padding:.6rem 0;font-size:.9rem;"/>
                </div>

                <button type="submit" class="btn-acceso" style="margin-top:1.2rem;">Guardar cambios</button>
            </form>
        </div>
    </div>
</body>
</html>
