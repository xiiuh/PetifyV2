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

    

    String accion = request.getParameter("accion");
    String errorCarrito = null;

    if ("eliminar".equals(accion)) {
        String idStr = request.getParameter("id_producto");
        if (idStr != null) {
            try { carrito.remove(Integer.parseInt(idStr)); } catch (NumberFormatException ignored) {}
        }
        response.sendRedirect(request.getContextPath() + "/tutor/carritoCompras.jsp");
        return;
    }

    if ("cancelar".equals(accion)) {
        session.removeAttribute("carrito");
        response.sendRedirect(request.getContextPath() + "/tienda.jsp");
        return;
    }

    if ("confirmar".equals(accion) && !carrito.isEmpty()) {
        String metodoPago = request.getParameter("metodo_pago");
        if (!"tarjeta".equals(metodoPago)) metodoPago = "efectivo";

        Context ctx2 = new InitialContext();
        DataSource ds2 = (DataSource) ctx2.lookup("java:comp/env/jdbc/petify");
        Connection con2 = ds2.getConnection();
        try {
            PreparedStatement ps2 = con2.prepareStatement("SELECT id_tutor FROM tutor WHERE correo = ?");
            ps2.setString(1, correo);
            ResultSet rs2 = ps2.executeQuery();
            int idTutor = 0;
            if (rs2.next()) idTutor = rs2.getInt("id_tutor");
            rs2.close(); ps2.close();

            double total = 0;
            Map<Integer, double[]> detalles = new LinkedHashMap<>();

            for (Map.Entry<Integer, Integer> entry : carrito.entrySet()) {
                ps2 = con2.prepareStatement(
                    "SELECT nombre, precio, cantidad FROM productos WHERE id_producto = ?");
                ps2.setInt(1, entry.getKey());
                rs2 = ps2.executeQuery();
                if (rs2.next()) {
                    int stockDisp = rs2.getInt("cantidad");
                    if (stockDisp < entry.getValue()) {
                        errorCarrito = "Stock insuficiente para: " + rs2.getString("nombre");
                        rs2.close(); ps2.close();
                        break;
                    }
                    double precio = rs2.getDouble("precio");
                    total += precio * entry.getValue();
                    detalles.put(entry.getKey(), new double[]{ precio, entry.getValue() });
                }
                rs2.close(); ps2.close();
            }

            if (errorCarrito == null) {
                con2.setAutoCommit(false);

                ps2 = con2.prepareStatement(
                    "INSERT INTO ordenes (id_tutor, total, metodo_pago) VALUES (?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS);
                ps2.setInt(1, idTutor);
                ps2.setDouble(2, total);
                ps2.setString(3, metodoPago);
                ps2.executeUpdate();
                rs2 = ps2.getGeneratedKeys();
                int idOrden = 0;
                if (rs2.next()) idOrden = rs2.getInt(1);
                rs2.close(); ps2.close();

                for (Map.Entry<Integer, double[]> d : detalles.entrySet()) {
                    ps2 = con2.prepareStatement(
                        "INSERT INTO detalle_orden (id_orden, id_producto, cantidad, precio_unitario) VALUES (?,?,?,?)");
                    ps2.setInt(1, idOrden);
                    ps2.setInt(2, d.getKey());
                    ps2.setInt(3, (int) d.getValue()[1]);
                    ps2.setDouble(4, d.getValue()[0]);
                    ps2.executeUpdate();
                    ps2.close();

                    ps2 = con2.prepareStatement(
                        "UPDATE productos SET cantidad = cantidad - ? WHERE id_producto = ?");
                    ps2.setInt(1, (int) d.getValue()[1]);
                    ps2.setInt(2, d.getKey());
                    ps2.executeUpdate();
                    ps2.close();
                }

                con2.commit();
                session.removeAttribute("carrito");
                session.setAttribute("ultimaOrden", idOrden);
                con2.close();
                response.sendRedirect(request.getContextPath() + "/tutor/ticketCompra.jsp");
                return;
            }
        } catch (Exception e) {
            try { con2.rollback(); } catch (Exception ignored) {}
            errorCarrito = "Error al procesar la compra. Intenta de nuevo.";
        } finally {
            if (con2 != null && !con2.isClosed()) con2.close();
        }
    }

    // Load data for rendering
    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();
    double total = 0;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Carrito – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">

    <div class="topbar">
        <span class="logo">PETIFY</span>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/tienda.jsp" class="btn-back">← Seguir comprando</a>
        <h2 class="page__title">Carrito de Compras</h2>

        <% if (errorCarrito != null) { %>
            <p class="error-msg" style="padding-left:0;margin-bottom:1rem;"><%= errorCarrito %></p>
        <% } %>

        <% if (carrito.isEmpty()) { %>
            <p style="color:var(--muted);">Tu carrito está vacío.</p>
        <% } else { %>

        <div class="card" style="padding:1.5rem;overflow-x:auto;">
            <table class="tabla">
                <thead>
                    <tr>
                        <th>Producto</th>
                        <th>Precio</th>
                        <th>Cantidad</th>
                        <th>Subtotal</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                <%
                    for (Map.Entry<Integer, Integer> item : carrito.entrySet()) {
                        PreparedStatement ps = con.prepareStatement(
                            "SELECT nombre, precio FROM productos WHERE id_producto = ?");
                        ps.setInt(1, item.getKey());
                        ResultSet rs = ps.executeQuery();
                        if (rs.next()) {
                            String nombre = rs.getString("nombre");
                            double precio = rs.getDouble("precio");
                            int    cant   = item.getValue();
                            double sub    = precio * cant;
                            total += sub;
                %>
                    <tr>
                        <td><%= nombre %></td>
                        <td>$<%= String.format("%.2f", precio) %></td>
                        <td><%= cant %></td>
                        <td>$<%= String.format("%.2f", sub) %></td>
                        <td>
                            <form method="post" style="margin:0;">
                                <input type="hidden" name="accion"      value="eliminar"/>
                                <input type="hidden" name="id_producto" value="<%= item.getKey() %>"/>
                                <button type="submit" class="btn-del"
                                        style="padding:.3rem .75rem;font-size:.85rem;">
                                    Eliminar
                                </button>
                            </form>
                        </td>
                    </tr>
                <%
                        }
                        rs.close(); ps.close();
                    }
                    con.close();
                %>
                </tbody>
                <tfoot>
                    <tr>
                        <th colspan="3">Total</th>
                        <th colspan="2">$<%= String.format("%.2f", total) %></th>
                    </tr>
                </tfoot>
            </table>
        </div>

        <div style="margin-top:1.8rem;">
            <h3 style="font-size:1rem;font-weight:700;color:var(--text);margin-bottom:1rem;">
                Método de pago
            </h3>
            <form method="post">
                <input type="hidden" name="accion" value="confirmar"/>
                <div style="display:flex;gap:1rem;flex-wrap:wrap;margin-bottom:1.4rem;">
                    <label style="flex:1;min-width:180px;display:flex;align-items:flex-start;gap:.75rem;
                                  background:var(--blue-pale);border:2px solid transparent;border-radius:12px;
                                  padding:1rem;cursor:pointer;transition:border-color .2s;"
                           onclick="this.style.borderColor='var(--blue-mid)';document.getElementById('lbl-tarjeta').style.borderColor='transparent';"
                           id="lbl-efectivo">
                        <input type="radio" name="metodo_pago" value="efectivo" checked
                               style="margin-top:3px;accent-color:var(--blue-mid);"/>
                        <div>
                            <strong style="display:block;margin-bottom:.2rem;">Efectivo</strong>
                            <span style="font-size:.82rem;color:var(--muted);">
                                Paga el total al recoger tu pedido en tienda
                            </span>
                        </div>
                    </label>
                    <label style="flex:1;min-width:180px;display:flex;align-items:flex-start;gap:.75rem;
                                  background:var(--blue-pale);border:2px solid transparent;border-radius:12px;
                                  padding:1rem;cursor:pointer;transition:border-color .2s;"
                           onclick="this.style.borderColor='var(--blue-mid)';document.getElementById('lbl-efectivo').style.borderColor='transparent';"
                           id="lbl-tarjeta">
                        <input type="radio" name="metodo_pago" value="tarjeta"
                               style="margin-top:3px;accent-color:var(--blue-mid);"/>
                        <div>
                            <strong style="display:block;margin-bottom:.2rem;">Tarjeta</strong>
                            <span style="font-size:.82rem;color:var(--muted);">
                                Pago online — solo preséntate a recoger
                            </span>
                        </div>
                    </label>
                </div>
                <div style="display:flex;gap:1rem;flex-wrap:wrap;">
                    <button type="submit" class="btn-acceso" style="width:auto;padding:.7rem 2rem;">
                        Confirmar compra
                    </button>
                </div>
            </form>
            <form method="post" style="margin-top:.75rem;">
                <input type="hidden" name="accion" value="cancelar"/>
                <button type="submit" class="btn-del" style="padding:.5rem 1.2rem;font-size:.85rem;">
                    Cancelar compra
                </button>
            </form>
        </div>

        <% } %>
        <% if (con != null && !con.isClosed()) con.close(); %>
    </div>
</body>
</html>
