local em = {}

local json = require("json")

-- CONFIG VARS --
em.token = '';
em.domain = "http://api.endermetrics.com/"
em.api_version = 'v1/';
em.session_token = nil;

-- ACCOUNT VARS--
em.account_id=0;

-- CHILD VARS --
em.childId=nil; --child & set var
em.nick = nil;
em.birthdate = nil;
em.gender = nil;
em.childlist = {};


-- SET VARS --
em.initTime = nil;
em.level = nil;
em.hits = {};
em.activityToken=nil;

-- DEBUG VARS--
em.isDebug=false;
em.stopTracking=false; --Variable para testear los juegos sin que endermetrics trackee nada

local networkConnection = true;



-- 	APP_TOKEN
-- Account: VARCHAR
-- Child:VARCHAR
-- ActivityToken:VARCHAR
-- Level:INTEGER
-- Result:
-- Time:INTEGER (ms)
-- dateTime:TIMESTAMP[opcional]
-- Hits: Array()


local function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
end	

--http://docs.coronalabs.com/api/library/network/request.html
--CHANGES!
-- PASAR DE (URL, RPARAMS, CALLBACK) A (url, params, data, callback)
function request(url, rparams, data, callback) 
	local headers = {}
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	headers["Accept-Language"] = "en-US"

	--{["asked"] = 5, ["correct"] = 3, ["wrong"] = 2}
	
	local p={}

	local no_session_url={'child/register/',
						  'account/register/',
						  'child/report/'
						  };
	
	if em.session_token == nil or table.indexOf(no_session_url,url)~=nil then

		log_message("debug", "--------------------")
		log_message("debug", "VARS SENT TO PARAMS:")
		
		-- Send params as a params session
		p = rparams;
		
		p.app_token=em.token;
		if url ~= 'account/getid/' then
			p.account_id=em.account_id
		end
		p.child_id = rparams.child_id
		p.custom_id=rparams.custom_id
		print("p.child_id")
		print(p.child_id)
		log_message("debug", "--------------------------------")
		log_message("debug","app_token: "..p.app_token)
				
	else
		p.session_token = em.session_token; --hay que checkear que si la sesion, account y child esten definidos
		p.data = data;
	end

	--json.encode({["app_token"]=em.token, ["account_id"]=''}
	local body = 'format=json&params='..json.encode(p);
	log_message("debug", "--------------------------------")
	log_message("debug","params: "..body);
	--print('params:'..body);

	local params = {}
	params.headers = headers
	params.body = body

	local rUrl = em.domain..em.api_version..url;
	log_message("debug", "--------------------------------")
	log_message("debug","Request to: "..rUrl)
	--print('Request to: '..rUrl);	
	network.request( rUrl, "POST",  function( event )
		if ( event.isError ) then
			log_message("error","Error sending request.")
			--print('Error sending request.')
			networkConnection=false;
			callback(false)
	        return false;
	    else
	    	log_message("debug", "--------------------------------")
	    	log_message("debug","Response: "..event.response)
	        --print ( "RESPONSE: " .. event.response )
	        local data = json.decode(event.response);
	        if data.meta then
		        printTable(data.meta);
		        if(data.meta.code == 200) then
		        	-- OK it works
		        	if(data.result==1)then
		        		if( data.data ~= nil)then
		        			callback(data.data);
		        		elseif (data.session_token ~= nil) then
		        			callback(data);
		        		else
		        			callback();
		        		end
		        	else
		        		log_message("debug", "--------------------------------")
		        		log_message("error", "Request failed.")
		        		-- print('Request failed');
		        		return false;
		        	end
		        	return true;
		        else
		        	-- if error then
		        	if(data.meta.code == 400) then
		        		log_message("debug", "--------------------------------")
		        		log_message("error","Error 400, message: "..data.meta.message)
			        	--print( "Error 400, message: "..data.meta.message );
			        end
			        return false;
		        end
		    else
		    	log_message("debug", "-----------------")
		        log_message("error","No data meta.")
		    end
	    end
	end, params);
	
end


function printTable(table)
	for key,value in pairs(table) do
	    print( "key: "..key.." value: "..value );

	end
end


function log_message(t, message) --log_message("error", "message to send")
	
	if t == "error" and em.isDebug then print("EM --> ERROR: "..message) end;
	if t == "debug" and em.isDebug then print("EM --> "..message) end;
	if t=="info" then print("EM -->"..message) end;

end




----------------------------------------------------------------------------------------------------
------------------------------------------------INIT------------------------------------------------
----------------------------------------------------------------------------------------------------

	function em:init(token)
		print("entro en init")
		if(em.isDebug) then
			log_message("--------------")
			log_message("debug mode: ON")
			log_message("Init token")
		end
		if em.stopTracking==false then
			em.token = token;
		end
	end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------
----------------------------------------------ACCOUNT-----------------------------------------------
----------------------------------------------------------------------------------------------------

	
	function em.getAccount()
		if em.stopTracking==false then
			log_message("debug", "----------------")
			log_message("debug", "-- Get account: ")

			return em.account_id;
		end
	end

	-- return the account registered
	function em:accountRegister(custom_id, callback)
		if em.stopTracking==false then
			log_message("debug", "-------------------------")
			log_message("debug", "-- Registering account...")
			log_message("debug, ", "--Custom_id: "..custom_id)
			local custom_id = custom_id or '';
			local params = {["custom_id"] = custom_id};

			if networkConnection then
				request('account/register/', params, nil, function(data)
					em.account_id=data.account_id;
					callback(data.account_id);
				end);
			end
		end
	end

	--return the account_id from a custom id
	function em:getId(custom_id, callback)
		--tiene que devolver Account_id":"123l4jasdlfkja"
		if em.stopTracking==false then
			log_message("debug", "--------------------------------------")
			log_message("debug", "-- Getting account from a custom_id...")

			local params={["custom_id"] = custom_id}

			if networkConnection then
				request('account/getid/', params, nil, function(data)
					-- print("ACCOUNTID OBTENIDO DE GETIID")
					-- print(data.account_id)
					em.account_id=data.account_id;
					callback(data.account_id)
				end);
			end
		end
	end

	-- Cuando se inicia la aplicación, es necesario generar un token para poder hacer las siguientes peticiones a la API. Esta petición 
	-- ha de contener el token de la APP, la fecha/hora del momento de la solicitud y un identificador de la cuenta de usuario. 
	-- Este identificador puede ser uno personalizado o el Token de EnderMetrics.

	function em:accountAuth(account_id, child_id, callback)
		if em.stopTracking==false then
			log_message("debug", "-------------------")
			log_message("debug", "-- Creating Auth... ")
			
			em.session_token=nil;
			if em.token==nil then
				log_message("error", "---------------------------------------------------------")
				log_message("error", "app_token can't be nil. Use function em:init('app_token')")
				
			elseif account_id==nil and child_id==nil then
				log_message("error", "---------------------------------------------------")
				log_message("error", "account_id and child_id are nil, loading to default")
				
				em.account_id = "00000000000000000000000000000000"; 
				em.childId = "00000000000000000000000000000000"; 

				local params = {["app_token"]=em.token, ["account_id"] = em.account_id, ["child_id"]= em.childId}; 
				
				if networkConnection then
					request('auth/token/', params, nil, function(data)
						if data then
							--controlar que session token
							if #data.session_token == 32 then
								log_message("debug", "Session token correct: "..data.session_token)

								--print("Session token correct: "..data.session_token)
								em.session_token = data.session_token;
								callback();
								--print(data);
							else
								log_message("error", "---------------------------")
								log_message("error", "Unable to get session token.")
								networkConnection=false
							end
						else
							log_message("error", "----------")
							log_message("error", "Auth error")
						end
					end);
				end
			else
				
				local params = {["app_token"]=em.token, ["account_id"] = account_id, ["child_id"]= child_id};
			
				if networkConnection then
					request('auth/token/', params, nil, function(data)
						if data then
							--controlar que session token
							if #data.session_token == 32 then
								log_message("debug", "----------------------------------------------")
								log_message("debug", "Session token correct: "..data.session_token)

								--print("Session token correct: "..data.session_token)
								em.session_token = data.session_token;
								callback();
								--print(data);
							else

								log_message("error", "---------------------------")
								log_message("error", "Unable to get session token.")
								networkConnection=false
							end
						else
							log_message("error", "----------")
							log_message("error", "Auth error")
							--print("Auth error");
						end
					end);
				end
			end
		end
	end

----------------------------------------------------------------------------------------------------
--------------------------------------------END ACCOUNT---------------------------------------------
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
-----------------------------------------------CHILD------------------------------------------------
----------------------------------------------------------------------------------------------------
	

	function em:childRegister(nick, birthdate, gender, callback)
		if em.stopTracking==false then
			log_message("debug", "-----------------------")
			log_message("debug", "-- Registering child...")
			
			em.nick = nick or 'default';
			em.birthdate = birthdate or "undefined";
			em.gender = gender or "undefined";
			
			local params = {["nick"] = nick, ["birthdate"]= birthdate, ["gender"]= gender}
			
			if networkConnection then
				request('child/register/', params, nil, function(data)
					--printTable(data);
					em.childId=data.child_id;
					
					-- I created this object to refresh the table of em.childlist
					local c = {["app_token"]=em.token, ["account_id"]=em.account_id, ["nick"] = nick, ["birthdate"]= birthdate, ["gender"]= gender, ["id"]=em.childId}
					table.insert(em.childlist, c)
					--controlar respuesta data con el childID
					callback(data.child_id);
				end);
			end
		end
	end

	
	function em.getChild()
		if em.stopTracking==false then
			log_message("debug", "-------------")
			log_message("debug", "-- Get child:")

			return em.child_id;
		end
	end



	-- Return the child list of an account
	function em:getAll(callback)
		if em.stopTracking==false then
			log_message("debug", "-------------------")
			log_message("debug", "-- Getting child...")
			
			--check if childlist is empty, if not create list
			if #em.childlist == 0 then 
				local params = {} --{["account_id"]= em.account_id}
				if networkConnection then
					request('child/getall/', params, nil, function(data)
						--table.insert(em.childList, data.list);
						
						if data == false then
							print("NETWORK DON'T WORK")
							callback(false)
						else 
							em.childlist = data.list
							callback(data.list)
						end
					end)
				else
					callback(false)
				end

			else 
				callback(em.childlist)
			end
		end
	end

----------------------------------------------------------------------------------------------------
---------------------------------------------END CHILD----------------------------------------------
----------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------
------------------------------------------------SET-------------------------------------------------
----------------------------------------------------------------------------------------------------

	function em:initSet( activityToken, level )  --initialize set to 0
		if em.stopTracking==false then
			log_message("debug", "--------------")
			log_message("debug", "-- Init set... ")
			log_message("debug", "--------------")
			log_message("debug", "Level of set: "..level)
			--print(level)
			
			local time = os.date( '*t' ); 
			em.initTime = os.time( time ); --returns time that set is created in seconds
			--em.childId = childId;
			em.activityToken=activityToken;
			em.level = level;
			--em.hits = {};
			
			log_message("debug","Activity token: "..em.activityToken)
			--print("ACTIVITY TOKEN: "..em.activityToken)
		end
	end

	function em:addHit(hit) --add a hit at the table hits
		if em.stopTracking==false then
			log_message("debug", "----------------")
			log_message("debug", "-- Adding hit... ")
			
			if networkConnection then
				table.insert(em.hits, hit);
			end
			
			log_message("debug", "----------------")
			log_message("debug","Printing hits...")
			if em.isDebug then print(print_r(em.hits)) end
		end
	end

	function em:trackSet( result, callback ) --Track set info of Endermetrics
		if em.stopTracking==false then
			log_message("debug","--------------")
			log_message("debug","Traking set...")

			if networkConnection then
				local t = os.date( '*t');
				local finalTime=os.time(t); --t final - t inicial
				local timePlayed = finalTime - em.initTime
				--TODO: CONTROLAR LOS VALORES DE PARAMS
				local data = {["child_id"] = em.childId, ["activity_token"] = em.activityToken, ["level"]= em.level, ["result"]= result, ["time"]= timePlayed, ["dateTime"]=dateTime,["hits"]=em.hits}
				--log_message("debug","List of sent params: \n- child_id: "..em.childId.."\n- activity_token: "..em.activityToken.."\n- level: "..em.level.."\n- result: "..result.."\n- time: "..timePlayed.."\n- dateTime: "..dateTime.."\n- hits: "..em.hits.."\n")
				log_message("debug","Result of tracking: "..result);
				
					request('track/set/', nil, data, function()
						callback();
					end);
			
				em.hits = {};
			
			else
				callback()
			end
		end
	end

----------------------------------------------------------------------------------------------------
----------------------------------------------END SET-----------------------------------------------
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
-----------------------------------------------REPORT-----------------------------------------------
----------------------------------------------------------------------------------------------------

--This method gives you the possibility to create a child report. 
function em:childReport(child_id, callback)
	if em.stopTracking==false then
		log_message("debug", "---------------")
		log_message("debug", "Child report...")

		if networkConnection then
			local params = {["app_token"]=em.token, ["account_id"]=em.account_id, ["child_id"]=child_id;}

			request('child/report/', params, nil, function(data)
				-- print("PRINTING REPORT CHILD")
				-- print_r(data)
				print("entro en el child report.")
				if data then
					callback(data.activities)
				else
					print("devuelvo false")
					callback(false)
				end
			end)
		else 
			callback(false)
		end
	end
end

----------------------------------------------------------------------------------------------------
---------------------------------------------END REPORT---------------------------------------------
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
-----------------------------------------------TESTING----------------------------------------------
----------------------------------------------------------------------------------------------------

function em.setIsDebug(boolean)
	em.isDebug = boolean;
end


function em.setStopTracking(boolean)
	em.stopTracking = boolean;
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


return em;


