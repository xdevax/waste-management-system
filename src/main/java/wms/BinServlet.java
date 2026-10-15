package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/bins")
public class BinServlet extends HttpServlet {

    private final BinDAO dao = new BinDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("bins", dao.findAll());
            req.getRequestDispatcher("/bins.jsp").forward(req, res);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        try {
            if ("add".equals(action)) {
                dao.insert(req.getParameter("location"),
                           Double.parseDouble(req.getParameter("capacity")),
                           req.getParameter("waste_type"),
                           Integer.parseInt(req.getParameter("zone_id")));
            } else if ("update".equals(action)) {
                dao.updateCapacity(Integer.parseInt(req.getParameter("bin_id")),
                                   Double.parseDouble(req.getParameter("capacity")));
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("bin_id")));
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
        res.sendRedirect(req.getContextPath() + "/bins");
    }
}
