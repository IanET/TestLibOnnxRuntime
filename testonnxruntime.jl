using LibOnnxRuntime

papibase = OrtGetApiBase()
apibase = unsafe_load(papibase)
portapi = @ccall $(apibase.GetApi)(ORT_API_VERSION::UInt32)::Ptr{OrtApi}
ortapi = unsafe_load(portapi)

rpenv = Ref{Ptr{OrtEnv}}(0)
status = @ccall $(ortapi.CreateEnv)(ORT_LOGGING_LEVEL_VERBOSE::Cint, "Test"::Cstring, rpenv::Ref{Ptr{OrtEnv}})::Ptr{OrtStatus}
@info "CreateEnv" status rpenv[]

if status != Ptr{OrtStatus}(0)
    msg = (@ccall $(ortapi.GetErrorMessage)(status::Ptr{OrtStatus})::Cstring) |> unsafe_string
    code = @ccall $(ortapi.GetErrorCode)(status::Ptr{OrtStatus})::Cint
    println("Status: $code $msg")
end

rpsession_options = Ref(Ptr{OrtSessionOptions}(0))
status = @ccall $(ortapi.CreateSessionOptions)(rpsession_options::Ref{Ptr{OrtSessionOptions}})::Ptr{OrtStatus}
@info "CreateSessionOptions" status rpsession_options[]

# TBD