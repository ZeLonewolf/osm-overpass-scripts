[out:csv(cnt1,cnt2;false;",")][timeout:3600];
area(id:#AREA);
nwr[#TAG1](area)->.rb;
nwr[#TAG2](area)->.rv;
make stat
  cnt1=rb.count(ways)+rb.count(relations),
  cnt2=rv.count(ways)+rv.count(relations);
out;
