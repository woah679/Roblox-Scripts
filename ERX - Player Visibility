	local ToggleMemberVisibility

	ToggleMemberVisibility = Tabs.Settings:Toggle({
		Title = "Toggle Visibility",
		Desc = "Toggles if an ERX User can see that you have ERX Executed",
		Value = false,
		Callback = function(Value)
			local Info = LocalPlayer:FindFirstChild("RoleplayInfo")

			local LocalPlayerName = LocalPlayer.Name

			if not Info then
				WindUI:Notify({
					Title = "PlayerVisibility",
					Content = "No Info found? please try respawning and do this again",
					Duration = 5,
				})

				ToggleMemberVisibility:Set(false)
				return
			end

			if Value then
				local NewERXName

				if #LocalPlayerName >= 6 then
					local nameChars = {}
					for i = 1, #LocalPlayerName do
						nameChars[i] = LocalPlayerName:sub(i, i)
					end
					nameChars[2] = "E"
					nameChars[4] = "R"
					nameChars[6] = "X"
					NewERXName = table.concat(nameChars)
				else
					NewERXName = "JESRSX"
				end

				local NameResponse = ChangeRoleplayInfo:InvokeServer({
					["BackgroundStyle"] = Info.BackgroundStyle.Value,
					["HairColor"] = (Info.HairColor.Value ~= "" and Info.HairColor.Value or "Black"),
					["EyeColor"] = Info.EyeColor.Value,
					["HeightFeet"] = Info.HeightFeet.Value,
					["Age"] = Info.Age.Value,
					["Name"] = NewERXName,
					["Weight"] = Info.Weight.Value,
					["HeightInches"] = Info.HeightInches.Value,
					["License"] = "Active",
					["Gender"] = (Info.Gender.Value ~= "" and Info.Gender.Value or "Other")
				})

				if NameResponse ~= "Success" then
					NameResponse = ChangeRoleplayInfo:InvokeServer({
						["BackgroundStyle"] = Info.BackgroundStyle.Value,
						["HairColor"] = (Info.HairColor.Value ~= "" and Info.HairColor.Value or "Black"),
						["EyeColor"] = Info.EyeColor.Value,
						["HeightFeet"] = Info.HeightFeet.Value,
						["Age"] = Info.Age.Value,
						["Name"] = "zEzRzX",
						["Weight"] = Info.Weight.Value,
						["HeightInches"] = Info.HeightInches.Value,
						["License"] = "Active",
						["Gender"] = (Info.Gender.Value ~= "" and Info.Gender.Value or "Other")
					})
				end

				if NameResponse == "Success" then
					WindUI:Notify({
						Title = "PlayerVisibility",
						Content = "Changed Visibility successfully!",
						Duration = 5,
					})
				else
					WindUI:Notify({
						Title = "PlayerVisibility",
						Content = "Failed to set visibility",
						Duration = 5,
					})
				end
			elseif not Value and Functions:IsVisibleERXUser(LocalPlayer) then
				local Response = ChangeRoleplayInfo:InvokeServer({
					["BackgroundStyle"] = Info.BackgroundStyle.Value,
					["HairColor"] = (Info.HairColor.Value ~= "" and Info.HairColor.Value or "Black"),
					["EyeColor"] = Info.EyeColor.Value,
					["HeightFeet"] = Info.HeightFeet.Value,
					["Age"] = Info.Age.Value,
					["Name"] = LocalPlayerName,
					["Weight"] = Info.Weight.Value,
					["HeightInches"] = Info.HeightInches.Value,
					["License"] = "Active",
					["Gender"] = (Info.Gender.Value ~= "" and Info.Gender.Value or "Other")
				})

				if Response == "Success" then
					WindUI:Notify({
						Title = "PlayerVisibility",
						Content = "Changed Visibility successfully!",
						Duration = 5,
					})
				else
					WindUI:Notify({
						Title = "PlayerVisibility",
						Content = "Failed to set visibility....... Somehow",
						Duration = 5,
					})
				end
			end
		end,
	})
