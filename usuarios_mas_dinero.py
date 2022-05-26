import psycopg2
import pandas as pd
import plotly.express as px
import dash
import dash_core_components as dcc
import dash_html_components as html


conn = psycopg2.connect(host="localhost", port = 5432, database="exval", user="postgres", password="1204")
statment= """SELECT u.user_name, final.rank, final.total FROM divisas.users u
INNER JOIN (SELECT RANK() OVER(ORDER BY total DESC) AS rank, id_user, total FROM 
	(SELECT SUM(eur) AS total, id_user FROM 
	 (SELECT id_user, stk_to_eur(stk_code, c.amount) AS eur FROM divisas.capitals c) AS stocks GROUP BY id_user) AS TEUR) AS final
ON final.id_user = u.id;"""
df_orders= pd.read_sql_query(statment ,con=conn)
df_orders

app = dash.Dash()

fig = px.bar(df_orders, x="user_name", y="total")

app.layout = html.Div([
     html.H1('Users con mas dinero'),
     html.Div([dcc.Graph(figure=fig)])
])

if __name__ == '__main__':
    app.run_server(debug=True, use_reloader=False)
     