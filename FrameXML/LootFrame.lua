LOOTFRAME_NUMBUTTONS = 4;
NUM_GROUP_LOOT_FRAMES = 4;
MASTER_LOOT_THREHOLD = 4;
LOOT_SLOT_NONE = 0;
LOOT_SLOT_ITEM = 1;
LOOT_SLOT_MONEY = 2;
LOOT_SLOT_CURRENCY = 3;

function LootFrame_OnLoad(self)
	self:RegisterEvent("LOOT_OPENED");
	self:RegisterEvent("LOOT_SLOT_CLEARED");
	self:RegisterEvent("LOOT_SLOT_CHANGED");
	self:RegisterEvent("LOOT_CLOSED");
	self:RegisterEvent("OPEN_MASTER_LOOT_LIST");
	self:RegisterEvent("UPDATE_MASTER_LOOT_LIST");
	--hide button bar
	ButtonFrameTemplate_HideButtonBar(self);
end

function LootFrame_OnEvent(self, event, ...)
	if ( event == "LOOT_OPENED" ) then
		local autoLoot = ...;
		
		self.page = 1;
		LootFrame_Show(self);
		if ( not self:IsShown()) then
			CloseLoot(autoLoot == 0);	-- The parameter tells code that we were unable to open the UI
		end
	elseif ( event == "LOOT_SLOT_CLEARED" ) then
		local arg1 = ...;
		
		if ( not self:IsShown() ) then
			return;
		end

		local numLootToShow = LOOTFRAME_NUMBUTTONS;
		if ( self.numLootItems > LOOTFRAME_NUMBUTTONS ) then
			numLootToShow = numLootToShow - 1;
		end
		local slot = arg1 - ((self.page - 1) * numLootToShow);
		if ( (slot > 0) and (slot < (numLootToShow + 1)) ) then
			local button = _G["LootButton"..slot];
			if ( button ) then
				button:Hide();
			end
		end
		-- try to move second page of loot items to the first page
		local button;
		local allButtonsHidden = 1;

		for index = 1, LOOTFRAME_NUMBUTTONS do
			button = _G["LootButton"..index];
			if ( button:IsShown() ) then
				allButtonsHidden = nil;
			end
		end
		if ( allButtonsHidden and LootFrameDownButton:IsShown() ) then
			LootFrame_PageDown();
		end
		return;
	elseif ( event == "LOOT_SLOT_CHANGED" ) then
		local arg1 = ...;
		
		if ( not self:IsShown() ) then
			return;
		end

		local numLootToShow = LOOTFRAME_NUMBUTTONS;
		if ( self.numLootItems > LOOTFRAME_NUMBUTTONS ) then
			numLootToShow = numLootToShow - 1;
		end
		local slot = arg1 - ((self.page - 1) * numLootToShow);
		if ( (slot > 0) and (slot < (numLootToShow + 1)) ) then
			local button = _G["LootButton"..slot];
			if ( button ) then
				LootFrame_UpdateButton(slot);
			end
		end
	elseif ( event == "LOOT_CLOSED" ) then
		StaticPopup_Hide("LOOT_BIND");
		HideUIPanel(self);
		return;
	elseif ( event == "OPEN_MASTER_LOOT_LIST" ) then
		ToggleDropDownMenu(1, nil, GroupLootDropDown, LootFrame.selectedLootButton, 0, 0);
		return;
	elseif ( event == "UPDATE_MASTER_LOOT_LIST" ) then
		UIDropDownMenu_Refresh(GroupLootDropDown);
	end
end

local LOOT_UPDATE_INTERVAL = 0.5;
function LootFrame_OnUpdate(self, elapsed)
	self.timeSinceUpdate = (self.timeSinceUpdate or 0) + elapsed;
	if ( self.timeSinceUpdate >= LOOT_UPDATE_INTERVAL ) then
		self:SetScript("OnUpdate", nil);
		self.timeSinceUpdate = nil;
		LootFrame_Update();
	end
end

function LootFrame_UpdateButton(index)
	local numLootItems = LootFrame.numLootItems;
	--Logic to determine how many items to show per page
	local numLootToShow = LOOTFRAME_NUMBUTTONS;
	if ( numLootItems > LOOTFRAME_NUMBUTTONS ) then
		numLootToShow = numLootToShow - 1;
	end
	
	local button = _G["LootButton"..index];
		local slot = (numLootToShow * (LootFrame.page - 1)) + index;
		if ( slot <= numLootItems ) then	
			if ( LootSlotHasItem(slot) and index <= numLootToShow ) then
				local texture, item, quantity, quality, locked, isQuestItem, questId, isActive = GetLootSlotInfo(slot);
				local text = _G["LootButton"..index.."Text"];
				if ( texture ) then
					local color = ITEM_QUALITY_COLORS[quality];
					_G["LootButton"..index.."IconTexture"]:SetTexture(texture);
					text:SetText(item);
					if( locked ) then
						SetItemButtonNameFrameVertexColor(button, 1.0, 0, 0);
						SetItemButtonTextureVertexColor(button, 0.9, 0, 0);
						SetItemButtonNormalTextureVertexColor(button, 0.9, 0, 0);
					else
						SetItemButtonNameFrameVertexColor(button, 0.5, 0.5, 0.5);
						SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
						SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
					end
					
					local questTexture = _G["LootButton"..index.."IconQuestTexture"];
					if ( questId and not isActive ) then
						questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG);
						questTexture:Show();
					elseif ( questId or isQuestItem ) then
						questTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER);
						questTexture:Show();		
					else
						questTexture:Hide();
					end
					
					text:SetVertexColor(color.r, color.g, color.b);
					local countString = _G["LootButton"..index.."Count"];
					if ( quantity > 1 ) then
						countString:SetText(quantity);
						countString:Show();
					else
						countString:Hide();
					end
					button.slot = slot;
					button.quality = quality;
					button:Enable();
				else
					text:SetText("");
					_G["LootButton"..index.."IconTexture"]:SetTexture(nil);
					SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
					LootFrame:SetScript("OnUpdate", LootFrame_OnUpdate);
					button:Disable();
				end
				button:Show();
			else
				button:Hide();
			end
		else
			button:Hide();
		end
end

function LootFrame_Update()
	for index = 1, LOOTFRAME_NUMBUTTONS do
		LootFrame_UpdateButton(index);
	end
	if ( LootFrame.page == 1 ) then
		LootFrameUpButton:Hide();
		LootFramePrev:Hide();
	else
		LootFrameUpButton:Show();
		LootFramePrev:Show();
	end
	local numItemsPerPage = LOOTFRAME_NUMBUTTONS;
	if ( LootFrame.numLootItems > LOOTFRAME_NUMBUTTONS ) then
		numItemsPerPage = numItemsPerPage - 1;
	end
	if ( LootFrame.page == ceil(LootFrame.numLootItems / numItemsPerPage) or LootFrame.numLootItems == 0 ) then
		LootFrameDownButton:Hide();
		LootFrameNext:Hide();
	else
		LootFrameDownButton:Show();
		LootFrameNext:Show();
	end
end

function LootFrame_PageDown()
	LootFrame.page = LootFrame.page + 1;
	LootFrame_Update();
end

function LootFrame_PageUp()
	LootFrame.page = LootFrame.page - 1;
	LootFrame_Update();
end

function LootFrame_Show(self)
	self.numLootItems = GetNumLootItems();
	
	if ( GetCVar("lootUnderMouse") == "1" ) then
		self:Show();
		-- position loot window under mouse cursor
		local x, y = GetCursorPosition();
		x = x / self:GetEffectiveScale();
		y = y / self:GetEffectiveScale();

		local posX = x - 175;
		local posY = y + 25;
		
		if (self.numLootItems > 0) then
			posX = x - 40;
			posY = y + 55;
			posY = posY + 40;
		end

		if( posY < 350 ) then
			posY = 350;
		end

		self:ClearAllPoints();
		self:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", posX, posY);
		self:GetCenter();
		self:Raise();
	else
		ShowUIPanel(self);
	end
	
	LootFrame_Update();
	LootFramePortraitOverlay:SetTexture("Interface\\TargetingFrame\\TargetDead");
end

function LootFrame_OnShow(self)
	if( self.numLootItems == 0 ) then
		PlaySound("LOOTWINDOWOPENEMPTY");
	elseif( IsFishingLoot() ) then
		PlaySound("FISHING REEL IN");
		LootFramePortraitOverlay:SetTexture("Interface\\LootFrame\\FishingLoot-Icon");
	end
end

function LootFrame_OnHide()
	CloseLoot();
	-- Close any loot distribution confirmation windows
	StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION");
end

function LootButton_OnClick(self, button)
	-- Close any loot distribution confirmation windows
	StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION");
	
	LootFrame.selectedLootButton = self:GetName();
	LootFrame.selectedSlot = self.slot;
	LootFrame.selectedQuality = self.quality;
	LootFrame.selectedItemName = _G[self:GetName().."Text"]:GetText();

	LootSlot(self.slot);
end

function LootItem_OnEnter(self)
	local slot = ((LOOTFRAME_NUMBUTTONS - 1) * (LootFrame.page - 1)) + self:GetID();
	local slotType = GetLootSlotType(slot);
	if ( slotType == LOOT_SLOT_ITEM ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetLootItem(slot);
		CursorUpdate(self);
	end
	if ( slotType == LOOT_SLOT_CURRENCY ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetLootCurrency(slot);
		CursorUpdate(self);
	end
end

function GroupLootContainer_OnLoad(self)
	self.rollFrames = {};
	self.reservedSize = 100;
	GroupLootContainer_CalcMaxIndex(self);
end

function GroupLootContainer_CalcMaxIndex(self)
	local maxIdx = 0;
	for k, v in pairs(self.rollFrames) do
		maxIdx = max(maxIdx, k);
	end
	self.maxIndex = maxIdx;
end

function GroupLootContainer_AddFrame(self, frame)
	local idx = self.maxIndex + 1;
	for i=1, self.maxIndex do
		if ( not self.rollFrames[i] ) then
			idx = i;
			break;
		end
	end
	self.rollFrames[idx] = frame;

	if ( idx > self.maxIndex ) then
		self.maxIndex = idx;
	end

	GroupLootContainer_Update(self);
	frame:Show();
end

function GroupLootContainer_RemoveFrame(self, frame)
	local idx = nil;
	for k, v in pairs(self.rollFrames) do
		if ( v == frame ) then
			idx = k;
			break;
		end
	end

	if ( idx ) then
		self.rollFrames[idx] = nil;
		if ( idx == self.maxIndex ) then
			GroupLootContainer_CalcMaxIndex(self);
		end
	end
	frame:Hide();
	GroupLootContainer_Update(self);
end

function GroupLootContainer_ReplaceFrame(self, oldFrame, newFrame)
	for k, v in pairs(self.rollFrames) do
		if ( v == oldFrame ) then
			v:Hide();
			self.rollFrames[k] = newFrame;
			GroupLootContainer_Update(self);
			newFrame:Show();
			return true;
		end
	end
	return false;	--Didn't find a frame to replace.
end

function GroupLootContainer_Update(self)
	local lastIdx = nil;

	for i=1, self.maxIndex do
		local frame = self.rollFrames[i];
		if ( frame ) then
			frame:ClearAllPoints();
			frame:SetPoint("CENTER", self, "BOTTOM", 0, self.reservedSize * (i-1 + 0.5));
			lastIdx = i;
		end
	end

	if ( lastIdx ) then
		self:SetHeight(self.reservedSize * lastIdx);
		self:Show();
	else
		self:Hide();
	end
end

function GroupLootDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, nil, "MENU");
	self.initialize = GroupLootDropDown_Initialize;
end

function GroupLootDropDown_Initialize()
	local candidate;
	local info = UIDropDownMenu_CreateInfo();
	
	if ( UIDROPDOWNMENU_MENU_LEVEL == 2 ) then
		local lastIndex = UIDROPDOWNMENU_MENU_VALUE + 5 - 1;
		for i=UIDROPDOWNMENU_MENU_VALUE, lastIndex do
			candidate = GetMasterLootCandidate(LootFrame.selectedSlot, i);
			if ( candidate ) then
				-- Add candidate button
				info.text = candidate;
				info.fontObject = GameFontNormalLeft;
				info.value = i;
				info.notCheckable = 1;
				info.func = GroupLootDropDown_GiveLoot;
				UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL);
			end
		end
		return;
	end
	
	if ( IsInRaid() ) then
		-- In a raid
		info.isTitle = 1;
		info.text = GIVE_LOOT;
		info.fontObject = GameFontNormalLeft;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		for i=1, 40, 5 do
			for j=i, i+4 do
				candidate = GetMasterLootCandidate(LootFrame.selectedSlot, j);
				if ( candidate ) then
					-- Add raid group
					info.isTitle = nil;
					info.text = GROUP.." "..ceil(i/5);
					info.fontObject = GameFontNormalLeft;
					info.hasArrow = 1;
					info.notCheckable = 1;
					info.value = j;
					info.func = nil;
					UIDropDownMenu_AddButton(info);
					break;
				end
			end
		end
	else
		-- In a party
		for i=1, MAX_PARTY_MEMBERS+1, 1 do
			candidate = GetMasterLootCandidate(LootFrame.selectedSlot, i);
			if ( candidate ) then
				-- Add candidate button
				info.text = candidate;
				info.fontObject = GameFontNormalLeft;
				info.value = i;
				info.notCheckable = 1;
				info.value = i;
				info.func = GroupLootDropDown_GiveLoot;
				UIDropDownMenu_AddButton(info);
			end
		end
	end
end

function GroupLootDropDown_GiveLoot(self)
	if ( LootFrame.selectedQuality >= MASTER_LOOT_THREHOLD ) then
		local dialog = StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION", ITEM_QUALITY_COLORS[LootFrame.selectedQuality].hex..LootFrame.selectedItemName..FONT_COLOR_CODE_CLOSE, self:GetText());
		if ( dialog ) then
			dialog.data = self.value;
		end
	else
		GiveMasterLoot(LootFrame.selectedSlot, self.value);
	end
	CloseDropDownMenus();
end

function GroupLootFrame_OpenNewFrame(id, rollTime)
	local frame;
	for i=1, NUM_GROUP_LOOT_FRAMES do
		frame = _G["GroupLootFrame"..i];
		if ( not frame:IsShown() ) then
			frame.rollID = id;
			frame.rollTime = rollTime;
			frame.Timer:SetMinMaxValues(0, rollTime);
			GroupLootContainer_AddFrame(GroupLootContainer, frame);
			return;
		end
	end
end

function GroupLootFrame_EnableLootButton(button)
	button:Enable();
	button:SetAlpha(1.0);
	SetDesaturation(button:GetNormalTexture(), false);
end

function GroupLootFrame_DisableLootButton(button)
	button:Disable();
	button:SetAlpha(0.35);
	SetDesaturation(button:GetNormalTexture(), true);
end

function GroupLootFrame_OnShow(self)
	AlertFrame_FixAnchors();
	local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired = GetLootRollItemInfo(self.rollID);
	if (name == nil) then
		GroupLootContainer_RemoveFrame(GroupLootContainer, self);
		return;
	end
	
	self.IconFrame.Icon:SetTexture(texture);
	local borderTexCoord = LOOT_BORDER_QUALITY_COORDS[quality] or LOOT_BORDER_QUALITY_COORDS[ITEM_QUALITY_UNCOMMON];
	self.IconFrame.Border:SetTexCoord(unpack(borderTexCoord));
	self.Name:SetText(name);
	local color = ITEM_QUALITY_COLORS[quality];
	self.Name:SetVertexColor(color.r, color.g, color.b);
	self.Border:SetVertexColor(color.r, color.g, color.b);
	if ( count > 1 ) then
		self.IconFrame.Count:SetText(count);
		self.IconFrame.Count:Show();
	else
		self.IconFrame.Count:Hide();
	end
	
	if ( canNeed ) then
		GroupLootFrame_EnableLootButton(self.NeedButton);
		self.NeedButton.reason = nil;
	else
		GroupLootFrame_DisableLootButton(self.NeedButton);
		self.NeedButton.reason = _G["LOOT_ROLL_INELIGIBLE_REASON"..reasonNeed];
	end
	if ( canGreed) then
		GroupLootFrame_EnableLootButton(self.GreedButton);
		self.GreedButton.reason = nil;
	else
		GroupLootFrame_DisableLootButton(self.GreedButton);
		self.GreedButton.reason = _G["LOOT_ROLL_INELIGIBLE_REASON"..reasonGreed];
	end
	if ( canDisenchant) then
		GroupLootFrame_EnableLootButton(self.DisenchantButton);
		self.DisenchantButton.reason = nil;
	else
		GroupLootFrame_DisableLootButton(self.DisenchantButton);
		self.DisenchantButton.reason = format(_G["LOOT_ROLL_INELIGIBLE_REASON"..reasonDisenchant], deSkillRequired);
	end
	self.Timer:SetFrameLevel(self:GetFrameLevel() - 1);
end

function GroupLootFrame_OnHide (self)
	AlertFrame_FixAnchors();
end

function GroupLootFrame_OnEvent(self, event, ...)
	if ( event == "CANCEL_LOOT_ROLL" ) then
		local arg1 = ...;
		if ( arg1 == self.rollID ) then
			GroupLootContainer_RemoveFrame(GroupLootContainer, self);
			StaticPopup_Hide("CONFIRM_LOOT_ROLL", self.rollID);
		end
	end
end

function GroupLootFrame_OnUpdate(self, elapsed)
	local left = GetLootRollTimeLeft(self:GetParent().rollID);
	local min, max = self:GetMinMaxValues();
	if ( (left < min) or (left > max) ) then
		left = min;
	end
	self:SetValue(left);
end

function BonusRollFrame_StartBonusRoll(spellID, text, duration)
	local frame = BonusRollFrame;
	local _, count, icon = GetCurrencyInfo(BONUS_ROLL_REQUIRED_CURRENCY);
	if ( count == 0 ) then
		return;
	end

	--Stop any animations that might still be playing
	frame.StartRollAnim:Stop();

	frame.state = "prompt";
	frame.spellID = spellID;
	frame.endTime = time() + duration;
	frame.remaining = duration;

	icon = "Interface\\Icons\\"..icon;
	local numRequired = 1;
	frame.PromptFrame.InfoFrame.Cost:SetFormattedText(BONUS_ROLL_COST, numRequired, icon);
	frame.CurrentCountFrame.Text:SetFormattedText(BONUS_ROLL_CURRENT_COUNT, count, icon);
	frame.PromptFrame.Timer:SetMinMaxValues(0, duration);
	frame.PromptFrame.Timer:SetValue(duration);
	frame.PromptFrame:Show();
	frame.RollingFrame:Hide();
	GroupLootContainer_AddFrame(GroupLootContainer, frame);
end

function BonusRollFrame_CloseBonusRoll()
	local frame = BonusRollFrame;
	if ( frame.state == "prompt" ) then
		GroupLootContainer_RemoveFrame(GroupLootContainer, frame);
	end
end

function BonusRollFrame_OnLoad(self)
	self:RegisterEvent("BONUS_ROLL_STARTED");
	self:RegisterEvent("BONUS_ROLL_FAILED");
	self:RegisterEvent("BONUS_ROLL_RESULT");
end

function BonusRollFrame_OnEvent(self, event, ...)
	if ( event == "BONUS_ROLL_FAILED" ) then
		--Do something?
	elseif ( event == "BONUS_ROLL_STARTED" ) then
		self.state = "rolling";
		self.animFrame = 0;
		self.animTime = 0;
		self.RollingFrame.LootSpinner:Show();
		self.RollingFrame.LootSpinnerFinal:Hide();
		self.StartRollAnim:Play();
	elseif ( event == "BONUS_ROLL_RESULT" ) then
		local rewardType, rewardLink, rewardQuantity = ...;
		self.state = "slowing";
		self.rewardType = rewardType;
		self.rewardLink = rewardLink;
		self.rewardQuantity = rewardQuantity;
		self.StartRollAnim:Finish();
	end
end

local finalAnimFrame = {
	item = 2,
	currency = 6,
	money = 6,
}

local finalTextureTexCoords = {
	item = {0.59570313, 0.62597656, 0.875, 0.9921875},
	currency = {0.56347656, 0.59375, 0.875, 0.9921875},
	money = {0.56347656, 0.59375, 0.875, 0.9921875},
}

function BonusRollFrame_OnUpdate(self, elapsed)
	if ( self.state == "prompt" ) then
		self.remaining = self.remaining - elapsed;
		self.PromptFrame.Timer:SetValue(max(0, self.remaining));
	elseif ( self.state == "rolling" ) then
		self.animTime = self.animTime + elapsed;
		if ( self.animTime > 0.05 ) then
			BonusRollFrame_AdvanceLootSpinnerAnim(self);
		end
	elseif ( self.state == "slowing" ) then
		self.animTime = self.animTime + elapsed;
		if ( self.animFrame == finalAnimFrame[self.rewardType] ) then
			self.state = "finishing";
			self.RollingFrame.LootSpinner:Hide();
			self.RollingFrame.LootSpinnerFinal:Show();
			self.RollingFrame.LootSpinnerFinal:SetTexCoord(unpack(finalTextureTexCoords[self.rewardType]));
			self.RollingFrame.LootSpinnerFinalText:SetText(_G["BONUS_ROLL_REWARD_"..string.upper(self.rewardType)]);
			self.FinishRollAnim:Play();
		elseif ( self.animTime > 0.1 ) then --Slow it down
			BonusRollFrame_AdvanceLootSpinnerAnim(self);
		end
	end
end

function BonusRollFrame_AdvanceLootSpinnerAnim(self)
	self.animTime = 0;
	self.animFrame = (self.animFrame + 1) % 8;
	local top = floor(self.animFrame / 4) * 0.5;
	local left = (self.animFrame % 4) * 0.25;
	self.RollingFrame.LootSpinner:SetTexCoord(left, left + 0.25, top, top + 0.5);
end

function BonusRollFrame_OnShow(self)
	self.PromptFrame.Timer:SetFrameLevel(self:GetFrameLevel() - 1);
	self.BlackBackgroundHoist:SetFrameLevel(self.PromptFrame.Timer:GetFrameLevel() - 1);
	--Update the remaining time in case we were hidden for some reason
	if ( self.state == "prompt" ) then
		self.remaining = self.endTime - time();
	end
end

function BonusRollFrame_FinishedFading(self)
	if ( self.rewardType == "item" ) then
		GroupLootContainer_ReplaceFrame(GroupLootContainer, self, BonusRollLootWonFrame);
		LootWonAlertFrame_SetUp(BonusRollLootWonFrame, self.rewardLink, self.rewardQuantity);
		AlertFrame_AnimateIn(BonusRollLootWonFrame);
	elseif ( self.rewardType == "money" ) then
		GroupLootContainer_ReplaceFrame(GroupLootContainer, self, BonusRollMoneyWonFrame);
		MoneyWonAlertFrame_SetUp(BonusRollMoneyWonFrame, self.rewardQuantity);
		AlertFrame_AnimateIn(BonusRollMoneyWonFrame);
	end
end

--
-- Missing Loot (when a player is not eligible for loot on an LFR boss kill)
--
function MissingLootFrame_Show()
	local missingLootFrame = MissingLootFrame;
	local numItems = GetNumMissingLootItems();
	if ( numItems == 0 ) then
		return;
	end
	
	for index = 1, numItems do
		local texture, name, count, quality = GetMissingLootItemInfo(index);
		local itemButton = _G["MissingLootFrameItem"..index];
		if ( not itemButton ) then
			-- create it
			itemButton = CreateFrame("BUTTON", "MissingLootFrameItem" .. index, missingLootFrame, "MissingLootButtonTemplate");
			if ( mod(index, 2) == 0 ) then
				itemButton:SetPoint("TOPLEFT", _G["MissingLootFrameItem"..(index - 1)], "TOPRIGHT", 118, 0);				
			else
				itemButton:SetPoint("TOPLEFT", _G["MissingLootFrameItem"..(index - 2)], "BOTTOMLEFT", 0, -6);
			end
			itemButton:SetID(index);
		end

		itemButton.icon:SetTexture(texture);
		itemButton.name:SetText(name);
		local color = ITEM_QUALITY_COLORS[quality];
		itemButton.name:SetVertexColor(color.r, color.g, color.b);
		if ( count > 1 ) then
			itemButton.count:SetText(count);
			itemButton.count:Show();
		else
			itemButton.count:Hide();
		end
	end
	for index = numItems + 1, missingLootFrame.numShownItems do
		_G["MissingLootFrameItem"..index]:Hide();
	end
	missingLootFrame.numShownItems = numItems;
	local numRows = ceil(numItems / 2);
	missingLootFrame:SetHeight(numRows * 43 + 36 + MissingLootFrameLabel:GetHeight());
	missingLootFrame:Show();
	AlertFrame_FixAnchors();
end

function MissingLootFrame_OnHide(self)
	AlertFrame_FixAnchors();
end

function MissingLootItem_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetMissingLootItem(self:GetID());
	CursorUpdate(self);
end
