<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%
    String _authToken = request.getParameter("token");
    if (_authToken == null || _authToken.trim().isEmpty()) {
        out.print("{\"success\":false,\"mensaje\":\"No autorizado\"}");
        return;
    }
    try {
        Context _authCtx = new InitialContext();
        DataSource _authDs = (DataSource) _authCtx.lookup("java:comp/env/jdbc/petify");
        Connection _authCon = _authDs.getConnection();
        PreparedStatement _authPs = _authCon.prepareStatement(
            "SELECT COUNT(*) FROM sesiones_api WHERE token=?");
        _authPs.setString(1, _authToken);
        ResultSet _authRs = _authPs.executeQuery();
        _authRs.next();
        boolean _authValid = _authRs.getInt(1) > 0;
        _authRs.close(); _authPs.close(); _authCon.close();
        if (!_authValid) {
            out.print("{\"success\":false,\"mensaje\":\"No autorizado\"}");
            return;
        }
    } catch (Exception _authEx) {
        out.print("{\"success\":false,\"mensaje\":\"Error de autenticación\"}");
        return;
    }
%>
