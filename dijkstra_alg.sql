CREATE OR REPLACE FUNCTION public.dijkstra_alg
(
    _vertices      JSONB,
    _edges         XML,
    _source_vertex TEXT,
    _target_vertex TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
AS $BODY$
DECLARE
    _Q         TEXT[];
    _neighbors TEXT[];
    _u         TEXT;
    _u_dist    INTEGER;
    _v         TEXT;
    _v_dist    INTEGER;
    _alt_dist  INTEGER;
BEGIN
    SELECT array_agg(t)
      INTO _Q
      FROM jsonb_object_keys(_vertices) t;
    
    _vertices = jsonb_set(_vertices, 
                 ARRAY[_source_vertex, 'dist'], 
                 0::TEXT::JSONB,
                 false
                );
    
    WHILE array_length(_Q, 1) > 0 LOOP
        
        SELECT t.key AS vertex, (t.value->>'dist')::INTEGER AS vertex_attributes
          INTO _u, _u_dist
          FROM jsonb_each(_vertices) t
         WHERE t.key =ANY (_Q)
         ORDER BY (t.value->>'dist')::INTEGER, t.key
         LIMIT 1;
        
        IF _u = _target_vertex THEN
            RETURN _vertices;
        END IF;
        
        _Q = array_remove(_Q, _u);
        
        WITH d AS
        (
            SELECT DISTINCT t.vertex::TEXT AS vertex
              FROM unnest(xpath('/edges/edge[@vertex_from="' || _u || '"]/@vertex_to', _edges) ||
                          xpath('/edges/edge[@vertex_to="' || _u || '"]/@vertex_from', _edges)) t(vertex)
             WHERE t.vertex::TEXT =ANY (_Q)
        )
        SELECT array_agg(d.vertex ORDER BY d.vertex)
          INTO _neighbors
          FROM d;
          
        IF _neighbors IS NULL THEN
            CONTINUE;
        END IF;
        
        FOREACH _v IN ARRAY _neighbors LOOP
            _alt_dist = _u_dist + 1;
            _v_dist = (_vertices->_v->>'dist')::INTEGER;
            IF _alt_dist < _v_dist THEN
                _vertices = jsonb_set(_vertices,
                                      ARRAY[_v, 'dist'], 
                                      _alt_dist::TEXT::JSONB,
                                      false
                                     );
                _vertices = jsonb_set(_vertices,
                                      ARRAY[_v, 'prev'], 
                                      ('"' || _u || '"')::JSONB,
                                      false
                                     );
            END IF;
        END LOOP;
     
    END LOOP;
    
    RETURN _vertices;
END
$BODY$;
