<html>
	<head>
		<title><? echo TITLE; ?></title>
		<? include(SNIPPETS . 'gui_head.php'); ?>
	</head>
	<body onload="onload_functions();">
	<div id="waitingdiv" style="position: absolute;height: 100%; width: 100%; display:none; z-index: 1000000; text-align: center">
			<div style="position: absolute;  top: 50%; left: 50%; transform: translate(-50%,-50%);">
				<i class="fa fa-spinner fa-7x wobble-fix spinner"></i>
			</div>
		</div>
		<a name="oben"></a>
		<table id="gui-table" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td align="center" valign="top">
					<form name="GUI" enctype="multipart/form-data" method="post" action="index.php" id="GUI">
						<div id="message_box"></div>		<!-- muss innerhalb des form stehen -->
						<table cellpadding=0 cellspacing=0>
							<tr> 
								<td colspan="2" id="header"><?php
									$this->debug->write("<br>Include <b>".LAYOUTPATH."snippets/".HEADER."</b> in gui.php",4);
									include(LAYOUTPATH."snippets/".HEADER); ?>
								</td>
							</tr>
							<tr>
								<td id="menuebar" valign="top" align="center"><?php
									include(SNIPPETS . "menue.php"); ?>
								</td>
								<td align="center" width="100%" height="100%" valign="top" background="<?php echo GRAPHICSPATH; ?>bg.gif" style="border-right: 1px solid; border-color: #FFFFFF #CCCCCC #CCCCCC;">
									<div style="height:100%; position: relative; overflow: hidden; ">		<!-- overflow wird f�r rausfliegende Legende ben�tigt und height:100% f�r den Box-Shadow unter der MapFunctionsBar und Legende -->
										<script type="text/javascript">
											currentform = document.GUI;
											<? $this->currentform = 'document.GUI'; ?>
										</script><?php
										$this->debug->write("<br>Include <b>".$this->main."</b> in gui.php",4);
										if(file_exists($this->main)){
											include($this->main);			# Pluginviews
										}
										else {
											include(LAYOUTPATH."snippets/".$this->main);		# normale snippets
										} ?>
									</div>
								</td>
							</tr>
							<tr> 
								<td colspan="2" id="footer"><?php
									$this->debug->write("<br>Include <b>".LAYOUTPATH."snippets/".FOOTER."</b> in gui.php",4);
									include(LAYOUTPATH."snippets/".FOOTER); ?>
								</td>
							</tr>
						</table>
						<input type="hidden" name="overlayx" value="<? echo $this->user->rolle->overlayx; ?>">
						<input type="hidden" name="overlayy" value="<? echo $this->user->rolle->overlayy; ?>">
						<input type="hidden" name="browserwidth">
						<input type="hidden" name="browserheight">
						<input type="hidden" name="stopnavigation" value="0">
						<input type="hidden" name="gle_changed" value="">
					</form><?
					if ($this->user->rolle->querymode == 1) {
						include(LAYOUTPATH.'snippets/overlayframe.php');
					} ?>
				</td>
			</tr><?php
			if ($this->user->funktion == 'admin' AND DEBUG_LEVEL > 0) { ?>
				<tr>
					<td>
						<div id="log">
							<?php echo readfile(LOGPATH.$_SESSION['login_name'].basename(DEBUGFILE)); ?>
						</div>
					</td>
				</tr><?php
			} ?>
			</table>
	</body>
</html>