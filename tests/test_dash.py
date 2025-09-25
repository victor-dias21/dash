import pytest
import time
from selenium import webdriver

chrome_path = "/home/victor/Scripting/pythonjenkins/dash/chrome-linux64/chrome"

chrome_options = webdriver.ChromeOptions()
chrome_options.binary_location = chrome_path
driver = webdriver.Chrome(options=chrome_options)

url = 'http://127.0.0.1:8080'

#teste da pagina inicial
driver.get(url)
time.sleep(10)
assert "Dash" in driver.title
assert "pagina inicial" in driver.page_source
print("Teste da pagina Inicial com sucesso!")

#teste da pagina formulario
driver.get(url + "/formulario")
time.sleep(10)
##assert "Dash" in driver.title
assert "Formulario" in driver.page_source
print("Teste da pagina Formulario com sucesso!")

#teste da pagina dos graficos
driver.get(url+ "/graficos")
time.sleep(10)
#assert "Dash" in driver.title
assert "Graficos" in driver.page_source
print("Teste da pagina de Graficos com sucesso!")

driver.quit()
