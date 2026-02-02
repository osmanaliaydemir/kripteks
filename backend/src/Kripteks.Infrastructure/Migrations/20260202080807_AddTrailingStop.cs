using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Kripteks.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddTrailingStop : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsTrailingStop",
                table: "Bots",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<decimal>(
                name: "MaxPriceReached",
                table: "Bots",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TrailingStopDistance",
                table: "Bots",
                type: "decimal(18,2)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsTrailingStop",
                table: "Bots");

            migrationBuilder.DropColumn(
                name: "MaxPriceReached",
                table: "Bots");

            migrationBuilder.DropColumn(
                name: "TrailingStopDistance",
                table: "Bots");
        }
    }
}
