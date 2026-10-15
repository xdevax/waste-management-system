package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet({"/pickups", "/pickups/edit"})
public class PickupServlet extends HttpServlet {

    private final PickupDAO dao = new PickupDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("binOpts", dao.binOptions());
            req.setAttribute("colOpts", dao.collectorOptions());
            if (req.getServletPath().endsWith("/edit")) {
                req.setAttribute("pk", dao.findById(Integer.parseInt(req.getParameter("id"))));
                req.getRequestDispatcher("/pickup-edit.jsp").forward(req, res);
                return;
            }
            req.setAttribute("search", req.getParameter("q"));
            req.setAttribute("pickups", dao.findAll(req.getParameter("q")));
            req.getRequestDispatcher("/pickups.jsp").forward(req, res);
        } catch (Exception e) { throw new ServletException(e); }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        try {
            if ("add".equals(action)) {
                dao.insert(Integer.parseInt(req.getParameter("bin_id")),
                           Integer.parseInt(req.getParameter("collector_id")),
                           req.getParameter("pickup_date"),
                           Double.parseDouble(req.getParameter("weight")));
                req.getSession().setAttribute("flash", "Pickup recorded");
            } else if ("update".equals(action)) {
                dao.update(Integer.parseInt(req.getParameter("pickup_id")),
                           Integer.parseInt(req.getParameter("bin_id")),
                           Integer.parseInt(req.getParameter("collector_id")),
                           req.getParameter("pickup_date"),
                           Double.parseDouble(req.getParameter("weight")));
                req.getSession().setAttribute("flash", "Pickup updated");
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("pickup_id")));
                req.getSession().setAttribute("flash", "Pickup deleted");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flash", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/pickups");
    }
}