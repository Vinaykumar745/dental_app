import json
import os
import pandas as pd
from datetime import datetime

def generate_excel_report():
    """
    Parses the pytest-json-report output (execution-results.json)
    and generates the required Excel sheets.
    """
    base_dir = os.path.dirname(os.path.dirname(__file__))
    json_path = os.path.join(base_dir, "reports", "JSON", "execution-results.json")
    excel_dir = os.path.join(base_dir, "reports", "Excel")
    os.makedirs(excel_dir, exist_ok=True)
    
    excel_path = os.path.join(excel_dir, "Automation_Test_Report.xlsx")
    
    if not os.path.exists(json_path):
        print(f"JSON results file not found at {json_path}. Skipping Excel report generation.")
        return

    with open(json_path, 'r') as f:
        data = json.load(f)

    tests = data.get("tests", [])
    
    all_tests = []
    passed_tests = []
    failed_tests = []
    skipped_tests = []
    
    for t in tests:
        nodeid = t.get("nodeid", "")
        # Extract module name from nodeid (e.g. tests/test_authentication.py::test_login -> test_authentication)
        module = nodeid.split("::")[0].split("/")[-1].replace(".py", "")
        test_name = nodeid.split("::")[-1]
        
        status = t.get("outcome", "unknown")
        duration = t.get("setup", {}).get("duration", 0) + t.get("call", {}).get("duration", 0) + t.get("teardown", {}).get("duration", 0)
        
        # Determine priority based on module name (mock logic, adjust as needed)
        priority = "High" if "authentication" in module or "crud" in module else "Medium"
        
        row = {
            "Test ID": nodeid,
            "Module": module,
            "Test Name": test_name,
            "Status": status.upper(),
            "Execution Time (s)": round(duration, 2),
            "Priority": priority,
            "Error Message": t.get("call", {}).get("crash", {}).get("message", "") if status == "failed" else ""
        }
        
        all_tests.append(row)
        if status == "passed":
            passed_tests.append(row)
        elif status == "failed":
            failed_tests.append(row)
        elif status == "skipped":
            skipped_tests.append(row)

    # Execution Metrics
    total = len(all_tests)
    passed_count = len(passed_tests)
    failed_count = len(failed_tests)
    skipped_count = len(skipped_tests)
    pass_rate = (passed_count / total * 100) if total > 0 else 0
    
    metrics = [{
        "Total Tests": total,
        "Passed": passed_count,
        "Failed": failed_count,
        "Skipped": skipped_count,
        "Pass Rate (%)": round(pass_rate, 2),
        "Execution Date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }]

    # Write to Excel with multiple sheets
    with pd.ExcelWriter(excel_path, engine='openpyxl') as writer:
        pd.DataFrame(all_tests).to_excel(writer, sheet_name="Executed Test Cases", index=False)
        pd.DataFrame(passed_tests).to_excel(writer, sheet_name="Passed Tests", index=False)
        pd.DataFrame(failed_tests).to_excel(writer, sheet_name="Failed Tests", index=False)
        pd.DataFrame(skipped_tests).to_excel(writer, sheet_name="Skipped Tests", index=False)
        pd.DataFrame(metrics).to_excel(writer, sheet_name="Execution Metrics", index=False)

    print(f"Excel report successfully generated at: {excel_path}")
    
    # Also save separate files as requested
    pd.DataFrame(failed_tests).to_excel(os.path.join(excel_dir, "Failed_Test_Cases.xlsx"), index=False)
    pd.DataFrame(passed_tests).to_excel(os.path.join(excel_dir, "Passed_Test_Cases.xlsx"), index=False)
    pd.DataFrame(metrics).to_excel(os.path.join(excel_dir, "Summary_Report.xlsx"), index=False)

if __name__ == "__main__":
    generate_excel_report()
