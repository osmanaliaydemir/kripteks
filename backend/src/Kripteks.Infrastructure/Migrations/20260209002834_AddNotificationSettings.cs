using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Kripteks.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "EnablePushNotifications",
                table: "SystemSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "FcmToken",
                table: "SystemSettings",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyBuySignals",
                table: "SystemSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyErrors",
                table: "SystemSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyGeneral",
                table: "SystemSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "NotifySellSignals",
                table: "SystemSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyStopLoss",
                table: "SystemSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "NotifyTakeProfit",
                table: "SystemSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EnablePushNotifications",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "FcmToken",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NotifyBuySignals",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NotifyErrors",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NotifyGeneral",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NotifySellSignals",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NotifyStopLoss",
                table: "SystemSettings");

            migrationBuilder.DropColumn(
                name: "NotifyTakeProfit",
                table: "SystemSettings");
        }
    }
}
