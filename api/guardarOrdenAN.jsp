<%@ page contentType="application/json;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    response.setCharacterEncoding("UTF-8");
    response.setHeader("Access-Control-Allow-Origin", "*");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if ("OPTIONS".equals(request.getMethod())) { response.setStatus(200); return; }

    String idTutorStr  = request.getParameter("id_tutor");
    String totalStr    = request.getParameter("total");
    String metodoPago  = request.getParameter("metodo_pago");
    // Items como parámetros repetidos: id_producto[]=1&cantidad[]=2&precio[]=45.99
    String[] ids       = request.getParameterValues("id_producto[]");
    String[] cantidades = request.getParameterValues("cantidad[]");
    String[] precios   = request.getParameterValues("precio[]");

    if (idTutorStr == null || totalStr == null || metodoPago == null ||
        ids == null || cantidades == null || precios == null || ids.length == 0) {
        out.print("{\"success\":false,\"mensaje\":\"Faltan parámetros obligatorios\"}");
        return;
    }

    if (ids.length != cantidades.length || ids.length != precios.length) {
        out.print("{\"success\":false,\"mensaje\":\"Los arrays de items no coinciden en longitud\"}");
        return;
    }

    Connection con = null;
    try {
        int    idTutor = Integer.parseInt(idTutorStr);
        double total   = Double.parseDouble(totalStr);

        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        con = ds.getConnection();
        con.setAutoCommit(false);

        // 1. Insertar orden
        PreparedStatement psOrden = con.prepareStatement(
            "INSERT INTO ordenes (id_tutor, total, metodo_pago) VALUES (?,?,?)",
            Statement.RETURN_GENERATED_KEYS);
        psOrden.setInt(1, idTutor);
        psOrden.setDouble(2, total);
        psOrden.setString(3, metodoPago);
        psOrden.executeUpdate();

        ResultSet rsKeys = psOrden.getGeneratedKeys();
        rsKeys.next();
        int idOrden = rsKeys.getInt(1);
        rsKeys.close(); psOrden.close();

        // 2. Insertar detalle y actualizar stock
        PreparedStatement psDetalle = con.prepareStatement(
            "INSERT INTO detalle_orden (id_orden, id_producto, cantidad, precio_unitario) VALUES (?,?,?,?)");
        PreparedStatement psStock = con.prepareStatement(
            "UPDATE productos SET cantidad = cantidad - ? WHERE id_producto = ? AND cantidad >= ?");

        for (int i = 0; i < ids.length; i++) {
            int    idProducto = Integer.parseInt(ids[i]);
            int    cant       = Integer.parseInt(cantidades[i]);
            double precio     = Double.parseDouble(precios[i]);

            psDetalle.setInt(1, idOrden);
            psDetalle.setInt(2, idProducto);
            psDetalle.setInt(3, cant);
            psDetalle.setDouble(4, precio);
            psDetalle.executeUpdate();

            psStock.setInt(1, cant);
            psStock.setInt(2, idProducto);
            psStock.setInt(3, cant);
            int updated = psStock.executeUpdate();
            if (updated == 0) {
                con.rollback();
                psDetalle.close(); psStock.close(); con.close();
                out.print("{\"success\":false,\"mensaje\":\"Stock insuficiente para producto " + idProducto + "\"}");
                return;
            }
        }
        psDetalle.close(); psStock.close();
        con.commit();
        con.close();

        out.print("{\"success\":true,\"id_orden\":" + idOrden + ",\"mensaje\":\"Orden registrada correctamente\"}");

    } catch (Exception e) {
        try { if (con != null) { con.rollback(); con.close(); } } catch (Exception ignored) {}
        out.print("{\"success\":false,\"mensaje\":\"Error interno\"}");
    }
%>
