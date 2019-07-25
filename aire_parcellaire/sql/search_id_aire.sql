SELECT ta.id_siqo, denomination, id_aire, lbl_aire, crinao
FROM t_siqo ts
LEFT JOIN t_aire ta ON concat(lpad(ts.id_app::text,4,'0'),lpad(ts.id_denom::text,4,'0')) = ta.id_siqo
LEFT JOIN t_crinao tc USING(id_crinao)
WHERE denomination ~* 'rhône'
ORDER BY denomination