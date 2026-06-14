<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, javax.servlet.http.*, java.io.*, java.nio.file.*, java.util.UUID, java.util.Set, java.util.HashSet, java.util.Arrays" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String error = null;

    if ("POST".equals(request.getMethod())) {
        String nombre      = request.getParameter("nombre");
        String descripcion = request.getParameter("descripcion");
        String precioStr   = request.getParameter("precio");
        String cantStr     = request.getParameter("cantidad");

        try {
            double precio   = Double.parseDouble(precioStr);
            int    cantidad = Integer.parseInt(cantStr);

            String imagenNombre = null;
            Part filePart = request.getPart("imagen");
            if (filePart != null && filePart.getSize() > 0) {
                String submitted = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                String ext = submitted.contains(".") ? submitted.substring(submitted.lastIndexOf('.')).toLowerCase() : "";
                Set<String> extsPermitidas = new HashSet<>(Arrays.asList(".jpg",".jpeg",".png",".gif",".webp"));
                if (!extsPermitidas.contains(ext)) throw new Exception("Tipo de archivo no permitido.");
                imagenNombre = UUID.randomUUID().toString() + ext;
                String uploadDir = application.getRealPath("/img/productos");
                new File(uploadDir).mkdirs();
                filePart.write(uploadDir + File.separator + imagenNombre);
            }

            Context ctx = new InitialContext();
            DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
            Connection con = ds.getConnection();
            PreparedStatement ps = con.prepareStatement(
                "INSERT INTO productos (nombre, descripcion, cantidad, precio, imagen) VALUES (?,?,?,?,?)");
            ps.setString(1, nombre);
            ps.setString(2, descripcion);
            ps.setInt(3, cantidad);
            ps.setDouble(4, precio);
            ps.setString(5, imagenNombre);
            ps.executeUpdate();
            ps.close(); con.close();

            response.sendRedirect(request.getContextPath() + "/veterinario/productos.jsp?ok=1");
            return;
        } catch (Exception e) {
            error = e.getMessage().startsWith("Tipo de archivo") ? e.getMessage() : "Error al registrar el producto. Intenta de nuevo.";
            System.err.println("[registrarProducto] " + e);
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registrar Producto – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">
    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/veterinario/productos.jsp" class="btn-back">← Volver</a>

        <div class="card card--register" style="max-width:560px;">
            <h2 class="card-title">Registrar Producto</h2>

            <% if (error != null) { %>
                <p class="error-msg" style="text-align:center;"><%= error %></p>
            <% } %>

            <form method="post" enctype="multipart/form-data">

                <div class="form-group">
                    <label>Nombre <span class="required">*</span></label>
                    <div class="input-wrap">
                        <input type="text" name="nombre" required placeholder="Ej. Alimento premium para perros"/>
                    </div>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Descripción</label>
                    <textarea name="descripcion" rows="3" placeholder="Descripción del producto..."
                              style="width:100%;background:var(--blue-pale);border:2px solid transparent;
                                     border-radius:12px;padding:11px 16px;font-family:'DM Sans',sans-serif;
                                     font-size:.94rem;color:var(--text);outline:none;resize:vertical;"></textarea>
                </div>

                <div class="form-row" style="margin-top:.9rem;">
                    <div class="form-group">
                        <label>Precio ($) <span class="required">*</span></label>
                        <div class="input-wrap">
                            <input type="number" name="precio" step="0.01" min="0" required placeholder="0.00"/>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Cantidad en stock <span class="required">*</span></label>
                        <div class="input-wrap">
                            <input type="number" name="cantidad" min="0" required placeholder="0"/>
                        </div>
                    </div>
                </div>

                <div class="form-group" style="margin-top:.9rem;">
                    <label>Imagen del producto</label>
                    <input type="file" name="imagen" accept="image/*"
                           style="width:100%;padding:.6rem 0;font-size:.9rem;"/>
                </div>

                <button type="submit" class="btn-acceso" style="margin-top:1.2rem;">Guardar producto</button>
            </form>
        </div>
    </div>
</body>
</html>
