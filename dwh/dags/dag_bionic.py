from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.clickhousedb.hooks.clickhouse import ClickHouseHook
import pandas as pd

def etl_users_telemetry_to_clickhouse():
    pg_users_hook = PostgresHook(postgres_conn_id='postgres_users')
    df_users = pg_users_hook.get_pandas_df(sql="SELECT user_id, username, email, full_name, phone FROM crm_users;")

    pg_telem_hook = PostgresHook(postgres_conn_id='postgres_telemetry')
    df_telemetry = pg_telem_hook.get_pandas_df(
        sql='''
            SELECT telemetry_id, user_id, device_id, event_time, payload 
            FROM user_telemetry 
            WHERE event_time >= NOW() - INTERVAL '1 day';
        '''
    )

    df_report = pd.merge(df_telemetry, df_users, on='user_id', how='inner')
    ch_hook = ClickHouseHook(clickhouse_conn_id='clickhouse_report')
    
    client = ch_hook.get_client()
    client.insert_df(
        table='user_events',
        df=df_report
    )

with DAG(
    dag_id='postgres_to_clickhouse_report',
    start_date=datetime(2026, 11, 11),
    schedule_interval='@daily',
    is_paused_upon_creation=False,
    catchup=False,
    tags=['etl', 'clickhouse'],
) as dag:

    run_etl = PythonOperator(
        task_id='merge_and_load',
        python_callable=etl_users_telemetry_to_clickhouse,
    )

    run_etl
