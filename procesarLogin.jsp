<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.util.concurrent.ConcurrentHashMap" %>
<%
    String usuario = request.getParameter("j_username");
    String password = request.getParameter("j_password");

    if (usuario == null || password == null) {
        response.sendRedirect("login.jsp?error=1");
        return;
    }

    // --- Brute force protection ---
    @SuppressWarnings("unchecked")
    ConcurrentHashMap<String, long[]> intentos =
        (ConcurrentHashMap<String, long[]>) application.getAttribute("loginIntentos");
    if (intentos == null) {
        intentos = new ConcurrentHashMap<>();
        application.setAttribute("loginIntentos", intentos);
    }

    final long BLOQUEO_MS  = 1 * 60 * 1000L; // 1 minuto (prueba)
    final int  MAX_INTENTOS = 5;

    String clave = request.getRemoteAddr() + ":" + usuario.toLowerCase().trim();
    long[] datos = intentos.getOrDefault(clave, new long[]{0, 0});
    long   ahora = System.currentTimeMillis();

    // Verificar si está bloqueado
    if (datos[0] >= MAX_INTENTOS && (ahora - datos[1]) < BLOQUEO_MS) {
        long minRestantes = ((BLOQUEO_MS - (ahora - datos[1])) / 60000) + 1;
        response.sendRedirect("login.jsp?error=bloqueado&min=" + minRestantes);
        return;
    }

    // Expiró el bloqueo — reiniciar contador
    if (datos[0] >= MAX_INTENTOS && (ahora - datos[1]) >= BLOQUEO_MS) {
        datos = new long[]{0, 0};
    }

    // --- Session fixation: invalidar sesión antes del login ---
    String urlOriginal = null;
    HttpSession sesionAnterior = request.getSession(false);
    if (sesionAnterior != null) {
        urlOriginal = (String) sesionAnterior.getAttribute("javax.servlet.forward.request_uri");
        sesionAnterior.invalidate();
    }

    try {
        request.login(usuario, password);

        // Login exitoso — limpiar intentos fallidos
        intentos.remove(clave);

        // Nueva sesión limpia post-login
        HttpSession nuevaSesion = request.getSession(true);

        if (urlOriginal != null) {
            response.sendRedirect(urlOriginal);
        } else if (request.isUserInRole("tutor")) {
            response.sendRedirect("tutor/dashboard.jsp");
        } else if (request.isUserInRole("veterinario")) {
            response.sendRedirect("veterinario/agenda.jsp");
        } else {
            response.sendRedirect("login.jsp?error=1");
        }

    } catch (Exception e) {
        // Login fallido — incrementar contador
        if (datos[0] == 0) datos[1] = ahora; // registrar inicio del conteo
        datos[0]++;
        intentos.put(clave, datos);
        response.sendRedirect("login.jsp?error=1");
    }
%>
