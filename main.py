from dash import Dash, dcc, html
from dash.dependencies import Input, Output
import dash_bootstrap_components as dbc
import paginas
from app import app

navegacao = dbc.NavbarSimple(
    children=[
        dbc.NavItem(dbc.NavLink("Gráficos", href="/graficos")),
        dbc.NavItem(dbc.NavLink("Formulário", href="/formulario")),
    ],
    brand="Dashboard",
    brand_href="/",
    color="primary",
    dark=True,
)

app.layout = html.Div([
    dcc.Location(id='url', refresh=False),
    navegacao,
    html.Div(id='conteudo')
])

@app.callback(
    Output('conteudo', 'children'),
    [Input('url', 'pathname')]    
)
def mostrar_pagina(pathname):
    if pathname == '/formulario':
        return paginas.formulario.layout
    elif pathname == '/graficos':
        return paginas.graficos.layout
    else:
        return html.P('pagina inicial')



app.run_server(debug=False, port=8081, host='0.0.0.0')
