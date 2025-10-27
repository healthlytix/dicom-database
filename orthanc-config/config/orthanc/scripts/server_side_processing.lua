function Initialize()
  print('initialize')
end

function makeValidLabel(input)
  local invalidCharacters = "[^%w_-]"
  return input:gsub(invalidCharacters, "-")
end

function OnStableStudy(studyId, tags, metadata)
  --PrintRecursive(tags)
  local studyInstUid = tags["StudyInstanceUID"] 
  local referringPhysicianName = tags["ReferringPhysicianName"]
  if referringPhysicianName == nil or referringPhysicianName == '' then
    print('OnStableStudy: StableAge elapsed, processing study ' .. studyInstUid .. ' but ReferringPhysician is null or blank. No action to take')
  else
    print('OnStableStudy: StableAge elapsed, labelling study ' .. studyInstUid .. ' with ReferringPhysician ' .. referringPhysicianName)
    RestApiPut("/studies/" .. studyId .. "/labels/RD-" .. makeValidLabel(referringPhysicianName), '')
  end
end

function Finalize()
  print('finalize')
end
