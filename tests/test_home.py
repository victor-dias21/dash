import time

def test_home(browser):
	url = "http://127.0.0.1:8080"
	browser.get(url)
	time.sleep(10)
	assert browser.title == "Dash"
	print("Teste da pagina Inicial com sucesso!")
