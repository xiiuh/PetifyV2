<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, java.util.*, java.net.*, java.io.*" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    HashMap<Integer, Integer> carrito = (HashMap<Integer, Integer>) session.getAttribute("carrito");
    if (carrito == null || carrito.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/tienda.jsp");
        return;
    }

    String stripeSecretKey = "sk_test_51TdheH37KbljF7nmUifl1B9O3arUiNrMlHcExOc7KFmLahG0G6M2wWfcypF4Wrd7gtR1fAZzyyfvkxZpQh27yjB500lauARd3f";
    String debugError = null;
    String debugBody  = null;

    try {
        Context ctx = new InitialContext();
        DataSource ds  = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
        Connection con = ds.getConnection();

        String baseUrl    = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath();
        String successUrl = baseUrl + "/tutor/procesarPago.jsp?session_id={CHECKOUT_SESSION_ID}";
        String cancelUrl  = baseUrl + "/tutor/carritoCompras.jsp";

        StringBuilder params = new StringBuilder();
        params.append("mode=payment");
        params.append("&success_url=").append(URLEncoder.encode(successUrl, "UTF-8"));
        params.append("&cancel_url=").append(URLEncoder.encode(cancelUrl, "UTF-8"));

        int i = 0;
        for (Map.Entry<Integer, Integer> entry : carrito.entrySet()) {
            PreparedStatement ps = con.prepareStatement(
                "SELECT nombre, precio FROM productos WHERE id_producto = ?");
            ps.setInt(1, entry.getKey());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String nombre   = rs.getString("nombre");
                long   centavos = Math.round(rs.getDouble("precio") * 100);
                int    cantidad = entry.getValue();

                params.append("&line_items[").append(i).append("][price_data][currency]=mxn");
                params.append("&line_items[").append(i).append("][price_data][unit_amount]=").append(centavos);
                params.append("&line_items[").append(i).append("][price_data][product_data][name]=")
                      .append(URLEncoder.encode(nombre, "UTF-8"));
                params.append("&line_items[").append(i).append("][quantity]=").append(cantidad);
                i++;
            }
            rs.close(); ps.close();
        }
        con.close();

        URL url = new URL("https://api.stripe.com/v1/checkout/sessions");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Authorization", "Bearer " + stripeSecretKey);
        conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        conn.setDoOutput(true);

        try (OutputStream os = conn.getOutputStream()) {
            os.write(params.toString().getBytes("UTF-8"));
        }

        int httpStatus = conn.getResponseCode();
        InputStream is = httpStatus >= 400 ? conn.getErrorStream() : conn.getInputStream();
        StringBuilder json = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"))) {
            String line;
            while ((line = br.readLine()) != null) json.append(line);
        }

        String body = json.toString();
        debugBody = body;

        if (httpStatus >= 400) {
            debugError = "Stripe respondió HTTP " + httpStatus + ": " + body;
        } else {
            int urlStart = body.indexOf("\"url\": \"") + 8;
            int urlEnd   = body.indexOf("\"", urlStart);
            String checkoutUrl = body.substring(urlStart, urlEnd)
                                     .replace("\\u0026", "&")
                                     .replace("\\/", "/");
            response.sendRedirect(checkoutUrl);
            return;
        }
    } catch (Exception e) {
        debugError = e.getClass().getSimpleName() + ": " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Error de pago – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">
    <div class="topbar">
        <span class="logo">PETIFY</span>
        <a href="${pageContext.request.contextPath}/logout.jsp" class="btn-logout">Cerrar sesión</a>
    </div>
    <div class="main-content">
        <a href="${pageContext.request.contextPath}/tutor/carritoCompras.jsp" class="btn-back">← Volver al carrito</a>
        <div class="card" style="max-width:640px;padding:2rem;margin-top:1rem;">
            <h2 class="card-title" style="color:var(--error);">Error al conectar con Stripe</h2>
            <p style="margin-top:.5rem;color:var(--muted);">
                No se pudo iniciar el pago. Detalle del error:
            </p>
            <pre style="margin-top:1rem;background:#fff5f5;border:1px solid #fcc;border-radius:8px;
                        padding:1rem;font-size:.8rem;overflow-x:auto;white-space:pre-wrap;color:var(--error);"><%= debugError != null ? debugError : "Error desconocido" %></pre>
        </div>
    </div>
</body>
</html>
