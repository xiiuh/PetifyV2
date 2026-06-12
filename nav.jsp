<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*, java.util.*" %>
<%!
    private static String escN(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
    }
%>
<%
    boolean _navLoggedIn = request.getUserPrincipal() != null;
    boolean _navIsTutor  = _navLoggedIn && request.isUserInRole("tutor");
    boolean _navIsVete   = _navLoggedIn && request.isUserInRole("veterinario");
    String  _navNombre   = "";
    String  _navCorreo   = _navLoggedIn ? request.getUserPrincipal().getName() : null;

    if (_navCorreo != null) {
        try {
            Context _ctx = new InitialContext();
            DataSource _ds = (DataSource) _ctx.lookup("java:comp/env/jdbc/petify");
            Connection _con = _ds.getConnection();
            String _sql = _navIsTutor
                ? "SELECT nom_tutor AS nom FROM tutor WHERE correo = ?"
                : "SELECT nom_vete AS nom FROM veterinario WHERE correo = ?";
            PreparedStatement _ps = _con.prepareStatement(_sql);
            _ps.setString(1, _navCorreo);
            ResultSet _rs = _ps.executeQuery();
            if (_rs.next()) _navNombre = _rs.getString("nom");
            _rs.close(); _ps.close(); _con.close();
        } catch (Exception _ex) {
            _navNombre = _navCorreo;
        }
    }

    String _dashUrl = _navIsTutor
        ? request.getContextPath() + "/tutor/dashboard.jsp"
        : request.getContextPath() + "/veterinario/agenda.jsp";

    @SuppressWarnings("unchecked")
    HashMap<Integer,Integer> _navCarrito = _navIsTutor
        ? (HashMap<Integer,Integer>) session.getAttribute("carrito")
        : null;
    int _cartCount = _navCarrito != null ? _navCarrito.size() : 0;
%>
<div class="topbar">
    <a href="<%= _navLoggedIn ? _dashUrl : request.getContextPath() + "/index.html" %>" class="logo">PETIFY</a>
    <div class="topbar-right">
        <% if (_navIsTutor) { %>
            <a href="<%= request.getContextPath() %>/tienda.jsp"           class="topbar-link">Tienda</a>
            <a href="<%= request.getContextPath() %>/tutor/misOrdenes.jsp" class="topbar-link">Mis pedidos</a>
        <% } %>
        <% if (_navLoggedIn) { %>
            <span class="user-welcome">Hola, <%= escN(_navNombre) %></span>
        <% } %>
        <% if (_navIsTutor) { %>
            <a href="<%= request.getContextPath() %>/tutor/carritoCompras.jsp" class="topbar-cart">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                    <circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
                    <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/>
                </svg>
                Carrito
                <span class="cart-badge"><%= _cartCount %></span>
            </a>
        <% } %>
        <% if (_navLoggedIn) { %>
            <a href="<%= request.getContextPath() %>/logout.jsp" class="btn-logout">Cerrar sesión</a>
        <% } else { %>
            <a href="<%= request.getContextPath() %>/login.jsp" class="topbar-cart">Iniciar sesión</a>
        <% } %>
    </div>
</div>
