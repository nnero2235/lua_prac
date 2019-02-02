#include<lua.h>
#include<lualib.h>
#include<sys/time.h>

static int getTimestampMillis(lua_State *L){
    struct timeval tv;
    gettimeofday(&tv, NULL);
    __int64_t ts = (__int64_t)tv.tv_sec*1000 + tv.tv_usec/1000;
    lua_pushnumber(L,ts);
    return 1;
}

int luaopen_cutils(lua_State *L){
    lua_register(L,"getTimestampMillis",getTimestampMillis);
    return 1;
}
