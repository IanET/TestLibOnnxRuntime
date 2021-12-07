import LibOnnxRuntime as ORT

papibase = ORT.OrtGetApiBase()
apibase = unsafe_load(papibase)
portapi = @ccall $(apibase.GetApi)(ORT.ORT_API_VERSION::UInt32)::Ptr{ORT.OrtApi}
ortapi = unsafe_load(portapi)

rpenv = Ref{Ptr{ORT.OrtEnv}}(0)
status = @ccall $(ortapi.CreateEnv)(ORT.ORT_LOGGING_LEVEL_WARNING::Cint, "Test"::Cstring, rpenv::Ref{Ptr{ORT.OrtEnv}})::Ptr{ORT.OrtStatus}
@show status

if status != Ptr{ORT.OrtStatus}(0)
    msg = (@ccall $(ortapi.GetErrorMessage)(status::Ptr{ORT.OrtStatus})::Cstring) |> unsafe_string
    code = @ccall $(ortapi.GetErrorCode)(status::Ptr{ORT.OrtStatus})::Cint
    println("Status: $code $msg")
end

rpsession_options = Ref(Ptr{ORT.OrtSessionOptions}(0))
status = @ccall $(ortapi.CreateSessionOptions)(rpsession_options::Ref{Ptr{ORT.OrtSessionOptions}})::Ptr{ORT.OrtStatus}
@show status

# TBD