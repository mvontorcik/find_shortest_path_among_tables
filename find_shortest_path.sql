CREATE OR REPLACE FUNCTION public.find_shortest_path
(
    _schema_blacklist   TEXT[],
    _vertices_blacklist TEXT[],
    _source_vertex      TEXT,
    _target_vertex      TEXT
)
RETURNS TABLE(dist INTEGER, vertex TEXT)
LANGUAGE plpgsql
AS $BODY$
DECLARE
    _curs_graph CURSOR (_schema_blacklist TEXT[], _vertices_blacklist TEXT[]) FOR
WITH edges_raw AS
(
SELECT DISTINCT nsp_from.nspname AS schema_from, rel_from.relname AS table_from, 
       nsp_to.nspname AS schema_to, rel_to.relname AS table_to
  FROM pg_constraint con
  JOIN pg_class rel_from
    ON rel_from.oid = con.conrelid
  JOIN pg_namespace nsp_from
    ON nsp_from.oid = rel_from.relnamespace
  JOIN pg_class rel_to
    ON rel_to.oid = con.confrelid
  JOIN pg_namespace nsp_to
    ON nsp_to.oid = rel_to.relnamespace
 WHERE con.contype = 'f'
   AND NOT nsp_from.nspname =ANY (COALESCE(_schema_blacklist, ARRAY['']))
   AND NOT nsp_to.nspname =ANY (COALESCE(_schema_blacklist, ARRAY['']))
   AND NOT nsp_from.nspname || '.' || rel_from.relname =ANY (COALESCE(_vertices_blacklist, ARRAY['.']))
   AND NOT nsp_to.nspname || '.' || rel_to.relname =ANY (COALESCE(_vertices_blacklist, ARRAY['.']))
   AND (nsp_from.nspname <> nsp_to.nspname OR rel_from.relname <> rel_to.relname)
),
vertices_names AS
(
SELECT DISTINCT schema_from || '.' || table_from AS vertex
  FROM edges_raw
UNION
SELECT DISTINCT schema_to || '.' || table_to AS vertex
  FROM edges_raw
),
vertices_count AS
(
SELECT COUNT(*) AS cnt
  FROM vertices_names
),
vertices AS
(
SELECT jsonb_object_agg(v.vertex, 
                          jsonb_build_object('dist', vertices_count.cnt+1, 
                                             'prev', ''
                                            )
                        ORDER BY v.vertex
                       ) AS vertices
  FROM vertices_names v
 CROSS JOIN vertices_count
),
edges AS
(
SELECT XMLElement
       (
           name edges, 
           XMLAgg
           (
               XMLElement
               (
                   name edge, 
                   xmlattributes(schema_from || '.' || table_from AS vertex_from,
                                 schema_to || '.' || table_to AS vertex_to
                                )
               )
           )
       ) AS edges
  FROM edges_raw
)
SELECT vertices.vertices, edges.edges
  FROM vertices
 CROSS JOIN edges;

    _vertices      JSONB;
    _edges         XML;
    _vertices_res  JSONB;
    _u             TEXT;
    _u_prev        TEXT;
    _u_dist        INTEGER;
BEGIN
    OPEN _curs_graph(_schema_blacklist, _vertices_blacklist);
    FETCH _curs_graph 
     INTO _vertices, _edges;
    CLOSE _curs_graph;
    
    _vertices_res = public.dijkstra_alg(_vertices, _edges, _source_vertex, _target_vertex);
    _u = _target_vertex;
    _u_prev = _vertices_res->_u->>'prev';
    -- Do something only if the vertex is reachable
    IF _u_prev <> '' OR _u = _source_vertex THEN
        -- Find the shortest path
        WHILE _u <> '' LOOP
            _u_dist = (_vertices_res->_u->>'dist')::INTEGER;
            -- Push the vertex onto the stack
            RETURN QUERY SELECT _u_dist, _u;
            -- Traverse from target to source
            _u = _u_prev;
            _u_prev = _vertices_res->_u->>'prev';
        END LOOP;
    END IF;
    RETURN;
END
$BODY$;
