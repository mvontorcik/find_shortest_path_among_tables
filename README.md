# find_shortest_path_among_tables
Alg for finding shortest path among tables in PostreSQL db

How to find which tables to join using shortest path algorithm

Sometimes it is hard to determine which tables to join if we need data from topologicaly distant tables in large and complex data model. Fortunately graph theory algorithms like shortest path algorithm can help us.

Implementation

Dijkstra's algorithm for finding the shortest paths between nodes in a graph is decribed in wikipedia at https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm.
The algorithm has only 19 lines of metacode:
 1  function Dijkstra(Graph, source):
 2
 3      for each vertex v in Graph.Vertices:            
 4          dist[v] ← INFINITY                 
 5          prev[v] ← UNDEFINED                
 6          add v to Q                     
 7      dist[source] ← 0                       
 8     
 9      while Q is not empty:
10          u ← vertex in Q with min dist[u]   
11          remove u from Q
12                                        
13          for each neighbor v of u still in Q:
14              alt ← dist[u] + Graph.Edges(u, v)
15              if alt < dist[v]:              
16                  dist[v] ← alt
17                  prev[v] ← u
18
19      return dist[], prev[]

I implemented the algorithm above in plpgsql using ARRAY, XML and JSON as data structures (in file dijkstra_alg.sql):
  1 CREATE OR REPLACE FUNCTION public.dijkstra_alg
  2 (   
  3     _vertices      JSONB,
  4     _edges         XML,
  5     _source_vertex TEXT,
  6     _target_vertex TEXT
  7 )
  8 RETURNS JSONB
  9 LANGUAGE plpgsql
 10 AS $BODY$
 11 DECLARE
 12     _Q         TEXT[];
 13     _neighbors TEXT[];
 14     _u         TEXT;
 15     _u_dist    INTEGER;
 16     _v         TEXT;
 17     _v_dist    INTEGER;
 18     _alt_dist  INTEGER;
 19 BEGIN
 20     SELECT array_agg(t)
 21       INTO _Q
 22       FROM jsonb_object_keys(_vertices) t;
 23 
 24     _vertices = jsonb_set(_vertices,
 25                  ARRAY[_source_vertex, 'dist'],
 26                  0::TEXT::JSONB,
 27                  false
 28                 );
 29 
 30     WHILE array_length(_Q, 1) > 0 LOOP
 31 
 32         SELECT t.key AS vertex, (t.value->>'dist')::INTEGER AS vertex_attributes
 33           INTO _u, _u_dist
 34           FROM jsonb_each(_vertices) t
 35          WHERE t.key =ANY (_Q)
 36          ORDER BY (t.value->>'dist')::INTEGER, t.key
 37          LIMIT 1;
 38 
 39         IF _u = _target_vertex THEN
 40             RETURN _vertices;
 41         END IF;
 42 
 43         _Q = array_remove(_Q, _u);
 44 
 45         WITH d AS
 46         (
 47             SELECT DISTINCT t.vertex::TEXT AS vertex
 48               FROM unnest(xpath('/edges/edge[@vertex_from="' || _u || '"]/@vertex_to', _edges) ||
 49                           xpath('/edges/edge[@vertex_to="' || _u || '"]/@vertex_from', _edges)) t(vertex)
 50              WHERE t.vertex::TEXT =ANY (_Q)
 51         )
 52         SELECT array_agg(d.vertex ORDER BY d.vertex)
 53           INTO _neighbors
 54           FROM d;
 55 
 56         IF _neighbors IS NULL THEN
 57             CONTINUE;
 58         END IF;
 59 
 60         FOREACH _v IN ARRAY _neighbors LOOP
 61             _alt_dist = _u_dist + 1;
 62             _v_dist = (_vertices->_v->>'dist')::INTEGER;
 63             IF _alt_dist < _v_dist THEN
 64                 _vertices = jsonb_set(_vertices,
 65                                       ARRAY[_v, 'dist'],
 66                                       _alt_dist::TEXT::JSONB,
 67                                       false
 68                                      );
 69                 _vertices = jsonb_set(_vertices,
 70                                       ARRAY[_v, 'prev'],
 71                                       ('"' || _u || '"')::JSONB,
 72                                       false
 73                                      );
 74             END IF;
 75         END LOOP;
 76 
 77     END LOOP;
 78 
 79     RETURN _vertices;
 80 END
 81 $BODY$;

The implementation is straightforward so I will only remark some details:
1. edges are given by FKs but in the code each edge is considered as undirected because for joining tables we don't care which table references and which table is referenced. So when we find neighbors we are looking for all tables referenced by table (vertex) _u (line 48) and all tables referencing the table (vertex) _u (line 49). XML is suitable to store data for such searching.
2. vertices (tables) are stored in JSONB. Qualified table name is the key and the value is JSONB with key/value pairs for dist and prev. Postgres provides function jsonb_set to update JSONB so we used it when needed.

Wrapper function find_shortest_path is implemented (in file find_shortest_path.sql) to make easier the calling of function dijkstra_alg.
It creates graph (i.e. edges and vertices), calls function dijkstra_alg, and read the shortest path from source to target by reverse iteration.
  1 CREATE OR REPLACE FUNCTION public.find_shortest_path
  2 (
  3     _schema_blacklist   TEXT[],
  4     _vertices_blacklist TEXT[],
  5     _source_vertex      TEXT,
  6     _target_vertex      TEXT
  7 )
  8 RETURNS TABLE(dist INTEGER, vertex TEXT)
  9 LANGUAGE plpgsql
 10 AS $BODY$
 11 DECLARE
 12     _curs_graph CURSOR (_schema_blacklist TEXT[], _vertices_blacklist TEXT[]) FOR
 13 WITH edges_raw AS
 14 (
 15 SELECT DISTINCT nsp_from.nspname AS schema_from, rel_from.relname AS table_from,
 16        nsp_to.nspname AS schema_to, rel_to.relname AS table_to
 17   FROM pg_constraint con
 18   JOIN pg_class rel_from
 19     ON rel_from.oid = con.conrelid
 20   JOIN pg_namespace nsp_from
 21     ON nsp_from.oid = rel_from.relnamespace
 22   JOIN pg_class rel_to
 23     ON rel_to.oid = con.confrelid
 24   JOIN pg_namespace nsp_to
 25     ON nsp_to.oid = rel_to.relnamespace
 26  WHERE con.contype = 'f'
 27    AND NOT nsp_from.nspname =ANY (COALESCE(_schema_blacklist, ARRAY['']))
 28    AND NOT nsp_to.nspname =ANY (COALESCE(_schema_blacklist, ARRAY['']))
 29    AND NOT nsp_from.nspname || '.' || rel_from.relname =ANY (COALESCE(_vertices_blacklist, ARRAY['.']))
 30    AND NOT nsp_to.nspname || '.' || rel_to.relname =ANY (COALESCE(_vertices_blacklist, ARRAY['.']))
 31    AND (nsp_from.nspname <> nsp_to.nspname OR rel_from.relname <> rel_to.relname)
 32 ),
 33 vertices_names AS
 34 (
 35 SELECT DISTINCT schema_from || '.' || table_from AS vertex
 36   FROM edges_raw
 37 UNION
 38 SELECT DISTINCT schema_to || '.' || table_to AS vertex
 39   FROM edges_raw
 40 ),
 41 vertices_count AS
 42 (
 43 SELECT COUNT(*) AS cnt
 44   FROM vertices_names
 45 ),
 46 vertices AS
 47 (
 48 SELECT jsonb_object_agg(v.vertex, 
 49                         jsonb_build_object('dist', vertices_count.cnt+1,
 50                                            'prev', ''
 51                                           )
 52                         ORDER BY v.vertex
 53                        ) AS vertices
 54   FROM vertices_names v
 55  CROSS JOIN vertices_count
 56 ),
 57 edges AS
 58 (
 59 SELECT XMLElement
 60        (
 61            name edges,
 62            XMLAgg
 63            (
 64                XMLElement
 65                (
 66                    name edge,
 67                    xmlattributes(schema_from || '.' || table_from AS vertex_from,
 68                                  schema_to || '.' || table_to AS vertex_to
 69                                 )
 70                )
 71            )
 72        ) AS edges
 73   FROM edges_raw
 74 )
 75 SELECT vertices.vertices, edges.edges
 76   FROM vertices
 77  CROSS JOIN edges;
 78 
 79     _vertices      JSONB;
 80     _edges         XML;
 81     _vertices_res  JSONB;
 82     _u             TEXT;
 83     _u_prev        TEXT;
 84     _u_dist        INTEGER;
 85 BEGIN
 86     OPEN _curs_graph(_schema_blacklist, _vertices_blacklist);
 87     FETCH _curs_graph
 88      INTO _vertices, _edges;
 89     CLOSE _curs_graph;
 90 
 91     _vertices_res = public.dijkstra_alg(_vertices, _edges, _source_vertex, _target_vertex);
 92     _u = _target_vertex;
 93     _u_prev = _vertices_res->_u->>'prev';
 94     -- Do something only if the vertex is reachable
 95     IF _u_prev <> '' OR _u = _source_vertex THEN
 96         -- Find the shortest path
 97         WHILE _u <> '' LOOP
 98             _u_dist = (_vertices_res->_u->>'dist')::INTEGER;
 99             -- Push the vertex onto the stack
100             RETURN QUERY SELECT _u_dist, _u;
101             -- Traverse from target to source
102             _u = _u_prev;
103             _u_prev = _vertices_res->_u->>'prev';
104         END LOOP;
105     END IF;
106     RETURN;
107 END
108 $BODY$;

Function find_shortest_path takes 4 parameters. Parameters _source_vertex and _target_vertex contain qualified table name, e.q. 'example.tab1'. Parameters _schema_blacklist and _vertices_blacklist limit the generated graph (lines 27-30) on which the shortest path is found. FK on same table is ignored (line 31).
Vertices count plus 1 is consider as INFINITY.
Postgres doesn't provide stack as data structure so on line 100 we append rows to the function's result set and caller can order them by dist to get the shortest path.

The usage

Let's create example schema to play - see file data_model.sql.
ER diagram (generated by graphviz) is in file example_tables0.svg.
Each table has column id_last_modified_by_user and FK to example.tab_users to simulate usual system tables.

Let's find shortest path from table 'example.tab31' to table 'example.tab12':
SELECT *
  FROM public.find_shortest_path
(
    _schema_blacklist   => ARRAY['pg_catalog', 'information_schema'],
    _vertices_blacklist => NULL::TEXT[],
    _source_vertex      => 'example.tab31',
    _target_vertex      => 'example.tab12'
) p
ORDER BY p.dist;

We get resultset:
"dist","vertex"
0,example.tab31
1,example.tab_users
2,example.tab12

As we see the shortest path goes through table 'example.tab_users' - see ER diagram in file example_tables1.svg.
It makes no sense to join tables in this way:
FROM example.tab31
JOIN example.tab_users USING (id_last_modified_by_user)
JOIN example.tab12 USING (id_last_modified_by_user)

Let's prohibit paths using system table 'example.tab_users':
SELECT *
  FROM public.find_shortest_path
(
    _schema_blacklist   => ARRAY['pg_catalog', 'information_schema'],
    _vertices_blacklist => ARRAY['example.tab_users'],
    _source_vertex      => 'example.tab31',
    _target_vertex      => 'example.tab12'
) p
ORDER BY p.dist;

We get resultset:
"dist","vertex"
0,example.tab31
1,example.tab22
2,example.tab1
3,example.tab12

As we see the path is longer and bypass system table 'example.tab_users' - see ER diagram in file example_tables2.svg.

The implemented algorithms consider edges as undirected so if we switch _source_vertex and _target_vertex we should get same path in reverse order:
SELECT *
  FROM public.find_shortest_path
(
    _schema_blacklist   => ARRAY['pg_catalog', 'information_schema'],
    _vertices_blacklist => ARRAY['example.tab_users'],
    _source_vertex      => 'example.tab12',
    _target_vertex      => 'example.tab31'
) p
ORDER BY p.dist;

We get resultset:
"dist","vertex"
0,example.tab12
1,example.tab1
2,example.tab22
3,example.tab31

Let's say the table 'example.tab22' has 0..1:1 cardinality to table 'example.tab31' so we want bypass it:
SELECT *
  FROM public.find_shortest_path
(
    _schema_blacklist   => ARRAY['pg_catalog', 'information_schema'],
    _vertices_blacklist => ARRAY['example.tab_users', 'example.tab22'],
    _source_vertex      => 'example.tab12',
    _target_vertex      => 'example.tab31'
) p
ORDER BY p.dist;

We get resultset:
"dist","vertex"
0,example.tab12
1,example.tab1
2,example.tab10
3,example.tab21
4,example.tab31

Again see ER diagram in file example_tables3.svg.

If we checked all transitions between tables and if they make sense from logical point of view we found the real path for joining source and target tables.

