import os
import pytest
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

def pytest_addoption(parser):
    parser.addoption(
        "--base-url",
        action="store",
        default=os.getenv("BASE_URL", "https://vinaykumar745.github.io/dental_app/"),
        help="Base URL for the application"
    )

@pytest.fixture(scope="session")
def base_url(request):
    return request.config.getoption("--base-url")

@pytest.fixture(scope="function")
def driver(request):
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    
    # Enable performance logging
    options.set_capability("goog:loggingPrefs", {"performance": "ALL", "browser": "ALL"})
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=options)
    
    # Global implicit wait (kept short, prefer explicit waits in POM)
    driver.implicitly_wait(5)
    
    yield driver
    
    driver.quit()

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """
    Hook to capture screenshot on test failure.
    """
    outcome = yield
    rep = outcome.get_result()
    
    # We only care about actual failing test calls, not setup/teardown
    if rep.when == "call" and rep.failed:
        driver = item.funcargs.get('driver', None)
        if driver:
            # Create screenshots directory if it doesn't exist
            screenshots_dir = os.path.join(os.path.dirname(__file__), "screenshots")
            os.makedirs(screenshots_dir, exist_ok=True)
            
            # Format filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            test_name = item.name
            screenshot_path = os.path.join(screenshots_dir, f"{test_name}_{timestamp}.png")
            
            try:
                driver.save_screenshot(screenshot_path)
            except Exception as e:
                print(f"Failed to take screenshot for {test_name}: {e}")
