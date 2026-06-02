<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, java.util.*, java.net.*, java.io.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String sessionId = request.getParameter("session_id");
    if (sessionId == null || sessionId.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/tutor/carritoCompras.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();
    HashMap<Integer, Integer> carrito = (HashMap<Integer, Integer>) session.getAttribute("carrito");
    if (carrito == null || carrito.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/tienda.jsp");
        return;
    }

    String stripeSecretKey = "sk_test_51TdheH37KbljF7nmUifl1B9O3arUiNrMlHcExOc7KFmLahG0G6M2wWfcypF4Wrd7gtR1fAZzyyfvkxZpQh27yjB500lauARd3f";

    // Verificar pago con Stripe
    URL url = new URL("https://api.stripe.com/v1/checkout/sessions/" + sessionId);
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestMethod("GET");
    conn.setRequestProperty("Authorization", "Bearer " + stripeSecretKey);

    StringBuilder json = new StringBuilder();
    try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"))) {
        String line;
        while ((line = br.readLine()) != null) json.append(line);
    }

    if (!json.toString().contains("\"payment_status\": \"paid\"")) {
        response.sendRedirect(request.getContextPath() + "/tutor/carritoCompras.jsp?error=pago");
        return;
    }

    // Procesar orden en la base de datos
    Context ctx = new InitialContext();
    DataSource ds  = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    try {
        PreparedStatement ps = con.prepareStatement("SELECT id_tutor FROM tutor WHERE correo = ?");
        ps.setString(1, correo);
        ResultSet rs = ps.executeQuery();
        int idTutor = 0;
        if (rs.next()) idTutor = rs.getInt("id_tutor");
        rs.close(); ps.close();

        double total = 0;
        Map<Integer, double[]> detalles = new LinkedHashMap<>();

        for (Map.Entry<Integer, Integer> entry : carrito.entrySet()) {
            ps = con.prepareStatement("SELECT precio FROM productos WHERE id_producto = ?");
            ps.setInt(1, entry.getKey());
            rs = ps.executeQuery();
            if (rs.next()) {
                double precio = rs.getDouble("precio");
                total += precio * entry.getValue();
                detalles.put(entry.getKey(), new double[]{ precio, entry.getValue() });
            }
            rs.close(); ps.close();
        }

        con.setAutoCommit(false);

        ps = con.prepareStatement(
            "INSERT INTO ordenes (id_tutor, total, metodo_pago) VALUES (?, ?, 'tarjeta')",
            Statement.RETURN_GENERATED_KEYS);
        ps.setInt(1, idTutor);
        ps.setDouble(2, total);
        ps.executeUpdate();
        rs = ps.getGeneratedKeys();
        int idOrden = 0;
        if (rs.next()) idOrden = rs.getInt(1);
        rs.close(); ps.close();

        for (Map.Entry<Integer, double[]> d : detalles.entrySet()) {
            ps = con.prepareStatement(
                "INSERT INTO detalle_orden (id_orden, id_producto, cantidad, precio_unitario) VALUES (?,?,?,?)");
            ps.setInt(1, idOrden); ps.setInt(2, d.getKey());
            ps.setInt(3, (int) d.getValue()[1]); ps.setDouble(4, d.getValue()[0]);
            ps.executeUpdate(); ps.close();

            ps = con.prepareStatement(
                "UPDATE productos SET cantidad = cantidad - ? WHERE id_producto = ?");
            ps.setInt(1, (int) d.getValue()[1]); ps.setInt(2, d.getKey());
            ps.executeUpdate(); ps.close();
        }

        con.commit();
        session.removeAttribute("carrito");
        session.setAttribute("ultimaOrden", idOrden);
        con.close();
        response.sendRedirect(request.getContextPath() + "/tutor/ticketCompra.jsp");

    } catch (Exception e) {
        try { con.rollback(); } catch (Exception ignored) {}
        if (con != null && !con.isClosed()) con.close();
        response.sendRedirect(request.getContextPath() + "/tutor/carritoCompras.jsp?error=proceso");
    }
%>
