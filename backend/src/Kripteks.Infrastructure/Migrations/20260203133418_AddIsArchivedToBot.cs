using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Kripteks.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIsArchivedToBot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsArchived",
                table: "Bots",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsArchived",
                table: "Bots");
        }
    }
}
