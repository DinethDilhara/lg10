INSERT INTO sources(source_id,name,endpoint,index_pattern)
VALUES (:'source_id', :'source_id', :'endpoint', :'index_pattern') ON CONFLICT DO NOTHING;
