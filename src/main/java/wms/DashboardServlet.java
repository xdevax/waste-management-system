package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final StatsDAO dao = new StatsDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("binCount", dao.binCount());
            req.setAttribute("colCount", dao.collectorCount());
            req.setAttribute("pickCount", dao.pickupCount());
            req.setAttribute("zoneCount", dao.zoneCount());
            req.setAttribute("totalKg", dao.totalWeight());
            req.setAttribute("perZone", dao.perZone());
            req.setAttribute("perCol", dao.perCollector());
            req.setAttribute("aboveAvg", dao.aboveAverage());
            req.getRequestDispatcher("/dashboard.jsp").forward(req, res);
        } catch (Exception e) { throw new ServletException(e); }
    }
}