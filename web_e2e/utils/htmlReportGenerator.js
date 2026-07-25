const fs = require('fs');
const path = require('path');

async function generateHtmlReport(stats, results, outDir) {
  const htmlPath = path.join(outDir, 'HTML');
  if (!fs.existsSync(htmlPath)) {
    fs.mkdirSync(htmlPath, { recursive: true });
  }

  const passRate = stats.total > 0 ? ((stats.passed / stats.total) * 100).toFixed(2) : 0;
  
  // Create rows
  const tableRows = results.map(r => `
    <tr class="${r.status === 'Pass' ? 'success' : 'fail'}">
      <td>${r.title}</td>
      <td><span class="badge ${r.status.toLowerCase()}">${r.status}</span></td>
      <td>${r.duration}ms</td>
      <td>${r.error || '-'}</td>
    </tr>
  `).join('');

  const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Mega E2E Execution Report</title>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #121212; color: #e0e0e0; margin: 0; padding: 20px; }
    h1 { text-align: center; color: #ffffff; border-bottom: 2px solid #333; padding-bottom: 10px; }
    .summary { display: flex; justify-content: space-around; margin: 20px 0; background-color: #1e1e1e; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
    .stat-box { text-align: center; }
    .stat-box h2 { margin: 0; font-size: 36px; }
    .stat-box p { margin: 5px 0 0; color: #aaa; text-transform: uppercase; letter-spacing: 1px; font-size: 12px; }
    .color-pass { color: #4caf50; }
    .color-fail { color: #f44336; }
    table { width: 100%; border-collapse: collapse; margin-top: 20px; background-color: #1e1e1e; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
    th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #333; }
    th { background-color: #2c2c2c; color: #fff; font-weight: 600; }
    tr:hover { background-color: #252525; }
    .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
    .badge.pass { background-color: rgba(76, 175, 80, 0.2); color: #4caf50; }
    .badge.fail { background-color: rgba(244, 67, 54, 0.2); color: #f44336; }
  </style>
</head>
<body>
  <h1>Execution Report (1,100 Tests)</h1>
  <div class="summary">
    <div class="stat-box"><h2>${stats.total}</h2><p>Total Tests</p></div>
    <div class="stat-box"><h2 class="color-pass">${stats.passed}</h2><p>Passed</p></div>
    <div class="stat-box"><h2 class="color-fail">${stats.failed}</h2><p>Failed</p></div>
    <div class="stat-box"><h2>${passRate}%</h2><p>Pass Rate</p></div>
  </div>
  <table>
    <thead>
      <tr>
        <th>Test Case</th>
        <th>Status</th>
        <th>Duration</th>
        <th>Error Details</th>
      </tr>
    </thead>
    <tbody>
      ${tableRows}
    </tbody>
  </table>
</body>
</html>`;

  const finalPath = path.join(htmlPath, 'execution-report.html');
  fs.writeFileSync(finalPath, htmlContent, 'utf-8');
  console.log(`HTML report saved to ${finalPath}`);
}

module.exports = { generateHtmlReport };
