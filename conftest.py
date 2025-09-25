import pytest
import time
from selenium import webdriver

@pytest.fixture(scope="module")
def browser():
	chrome_options = webdriver.ChromeOptions()
	chrome_options.add_argument("--headless")
	chrome_options.add_argument("--disable-gpu")
	
	driver = webdriver.Chrome(options=chrome_options)

	yield driver
	driver.quit()
