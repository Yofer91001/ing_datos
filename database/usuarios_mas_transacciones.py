##El link para visualizar la grafica aparece en consola al correr el codigo.

import psycopg2
import pandas as pd
import plotly.express as px
import dash
import dash_core_components as dcc
import dash_html_components as html


conn = psycopg2.connect(host="localhost", port = 5432, database="exval", user="postgres", password="1204")
statment= """SELECT RANK() OVER(ORDER BY total_transacciones), txu.* FROM txu;"""
df_orders= pd.read_sql_query(statment ,con=conn)
df_orders

app = dash.Dash()

fig = px.bar(df_orders, x="user_name", y="total_transacciones")

app.layout = html.Div([
     html.H1('Usuarios con mas transacciones'),
     html.Div([dcc.Graph(figure=fig)])
])

if __name__ == '__main__':
    app.run_server(debug=True, use_reloader=False)
    
