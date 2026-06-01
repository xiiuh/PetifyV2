<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@ page import="java.util.ArrayList" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width initial-scale=1.0">
    <title>Registro de compras</title>
    <link rel="stylesheet" href="estilo.css">
</head>

<body class="inicio">
<section class="inicio-seccion">

    <div class="boton-volver">
        <input type="button" class="boton boton-borde"
               value="← Volver al menú"
               onclick="location.href='dashboard.html'">
    </div>

    <div class="boton-volver2">
        <input type="button" class="boton boton-borde"
               value="← Volver"
               onclick="location.href='productos.html'">
        <h2 class="titulo-seccion">Registro de compras</h2>
    </div>

    <div class="grupo-formulario2">

        <!-- LAYOUT AISLADO -->
        <div class="registro-layout">

            <!-- IZQUIERDA: TABLA -->
            <div class="registro-izq registro-card">

                <div class="texto-centro">
                    <p class="titulo-seccion2">Inventario Completo</p>
                    <p class="subtitulo-seccion2">
                        Lista de todos los productos registrados
                    </p>
                </div>

                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Producto</th>
                            <th>Cantidad</th>
                            <th>Precio</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        Connection con = null;
                        PreparedStatement st = null;
                        ResultSet rs = null;

                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            con = DriverManager.getConnection(
                                "jdbc:mysql://localhost:3306/PAYSTREAM",
                                "root","n0m3l0"
                            );

                            st = con.prepareStatement(
                                "SELECT id, nombre, cantidad, precio FROM productos"
                            );
                            rs = st.executeQuery();

                            while (rs.next()) {
                    %>
                        <tr>
                            <td><%= rs.getInt("id") %></td>
                            <td><%= rs.getString("nombre") %></td>
                            <td><%= rs.getInt("cantidad") %></td>
                            <td>$<%= String.format("%.2f", rs.getDouble("precio")) %></td>
                        </tr>
                    <%
                            }
                        } catch (Exception e) {
                            out.println("<tr><td colspan='4'>Error</td></tr>");
                        } finally {
                            if (rs != null) rs.close();
                            if (st != null) st.close();
                            if (con != null) con.close();
                        }
                    %>
                    </tbody>
                </table>
            </div>

            <!-- DERECHA: FORM -->
            <div class="registro-der registro-card">

                <form action="registroCompra.jsp" method="post">
                    <div class="texto-centro">
                        <p class="titulo-seccion2">Agregar al carrito</p>
                        <p class="subtitulo-seccion2">
                            ID del producto y cantidad
                        </p>
                    </div>

                    <label>ID del producto</label>
                    <input class="input-datos2" type="number" name="idProducto" required>

                    <label>Cantidad</label>
                    <input class="input-datos2" type="number" name="cantidadCompra" min="1" required>

                    <button class="boton boton-primario"
                            type="submit"
                            name="accion"
                            value="agregar"
                            style="margin-top:15px">
                        Agregar al carrito
                    </button>
                </form>

                <form action="registroCompra.jsp" method="post" style="margin-top:10px;">
                    <button class="boton boton-borde"
                            type="submit"
                            name="accion"
                            value="verCarrito">
                        Ver carrito
                    </button>
                </form>

                <%
                    ArrayList<int[]> carrito =
                        (ArrayList<int[]>) session.getAttribute("carrito");

                    if (carrito == null) {
                        carrito = new ArrayList<>();
                        session.setAttribute("carrito", carrito);
                    }

                    String accion = request.getParameter("accion");

                    if ("agregar".equals(accion)) {
                        carrito.add(new int[] {
                            Integer.parseInt(request.getParameter("idProducto")),
                            Integer.parseInt(request.getParameter("cantidadCompra"))
                        });
                        out.println("<p style='color:green;'>Producto agregado</p>");
                    }

                    if ("verCarrito".equals(accion)) {
                        response.sendRedirect("carritoCompras.jsp");
                    }
                %>

            </div>

        </div>
    </div>
</section>
</body>
</html>
