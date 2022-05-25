##El link para visualizar la grafica aparece en consola al correr el codigo.

import psycopg2
import pandas as pd
import plotly.express as px
import dash
import dash_core_components as dcc
import dash_html_components as html


conn = psycopg2.connect(host="localhost", port = 5432, database="exval", user="postgres", password="1204")
statment= """SELECT s.name, r.total_amount, r.rank
FROM divisas.stocks s
INNER JOIN (SELECT RANK() OVER(ORDER BY total_amount DESC) AS rank, stk_to AS stock, total_amount FROM (SELECT SUM(amount) AS total_amount, stk_to FROM divisas.transactions GROUP BY stk_to) AS t) AS r
ON r.stock = s.code;"""
df_orders= pd.read_sql_query(statment ,con=conn)
df_orders

app = dash.Dash()

fig = px.bar(df_orders, x="name", y="total_amount")

app.layout = html.Div([
     html.H1('Monedas a las que mas se mueve dinero'),
     html.Div([dcc.Graph(figure=fig)])
])

if __name__ == '__main__':
    app.run_server(debug=True, use_reloader=False)
    
  
